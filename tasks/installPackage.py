import copy
from cumulusci.tasks.salesforce.install_package_version import InstallPackageVersion
from cumulusci.tasks.sfdx import SFDXOrgTask
from cumulusci.tasks.salesforce import BaseSalesforceApiTask
from cumulusci.salesforce_api.utils import get_simple_salesforce_connection
from cumulusci.core.config.util import get_devhub_config
from cumulusci.core.dependencies.utils import TaskContext
from cumulusci.core.utils import process_bool_arg
from cumulusci.core.config import TaskConfig
import pprint as pp
import json
from tasks.getDependencies import GetDependencies, package_query_fields, PackageVersion, PackageDependency

install_options = copy.deepcopy(InstallPackageVersion.task_options)
install_options["name"]["required"] = True
install_options["namespace"]["required"] = False

class InstallPackageDeps(BaseSalesforceApiTask):
    task_options = {
        "name": {
            "description": "The name of the package to install",
            "required": True,
        },
        "version": {
            "description": "The version of the package to install",
            "required": False,
        },
        "query_only": {
            "description": "The version of the package to install",
            "required": False,
            "default": False
        },
    }
    root_package = None
    packages = None

    def _init_options(self, kwargs):
        super(InstallPackageDeps, self)._init_options(kwargs)
        self.logger.info(f"Options: {self.options}")
        self.query_only = process_bool_arg(self.options.get("query_only", False))
        self.options["version"] = "latest"
        packageName = self.options['name']
        sfdxConfig = self.project_config.sfdx_project_config
        packagesDirs = [x for x in sfdxConfig["packageDirectories"]
                        if "package" in x.keys()]
        # check if the package is in the sfdx-project.json
        
        self.root_package = self._get_package_from_packages_by_name(packageName, packagesDirs)
        self.packages = packagesDirs
        self.aliases = sfdxConfig["packageAliases"]

    def _get_dependencies_for_package(self, packageName, dependencies=[]):
        self.logger.info(f"Determining dependencies for package: {packageName}")
        package = self._get_package_from_packages_by_name(packageName, self.packages)
        if package is None:
            return dependencies
        if "dependencies" in package:
            for dependency in package["dependencies"]:
                if "subscriberPackageId" in dependency:
                    pid = dependency["subscriberPackageId"]
                    dependencies = self._prepend_dependency(pid, dependencies)
                elif "package" in dependency:
                    # check if package in package dirs and if it has any dependencies
                    package_name = dependency["package"]
                    # check if package in aliases
                    pid = self._get_subscriber_package_id(package_name)
                    if pid is not None:
                        dependencies = self._prepend_dependency(pid, dependencies)
                    else:
                        versionNumber = 'latest'
                        if '@' in package_name:
                            self._prepend_dependency(f"{package_name}@{versionNumber}", dependencies)
                            package_name = package_name.split('@')[0]
                            versionNumber = package_name.split('@')[1]
                            return self._get_dependencies_for_package(package_name, dependencies)
                        elif 'versionNumber' in dependency:
                            versionNumber = dependency["versionNumber"]
                        
                        return self._get_dependencies_for_package(package_name, dependencies)
                        
        return dependencies
    
    def _prepend_dependency(self, dependency, dependencies):
        if dependency not in dependencies:
            dependencies.insert(0, dependency)
        return dependencies

    def _get_subscriber_package_id(self, packageName):
        if packageName in self.aliases:
            pid = self.aliases[packageName]
            # check if pid starts with 04t
            if pid.startswith('04t'):
                return pid
        return None
        

    def _get_package_from_packages_by_name(self, packageName, packages):
        for package in packages:
            if package["package"] == packageName:
                if packages == self.packages:
                    # pop from packages
                    return self.packages.pop(packages.index(package))
                return package
        return None

    def _get_dependency_package_ids(self, dependencies):
        package_ids = []
        for dependency in dependencies:
            package_id = self._get_package_id(dependency["subscriberPackageId"])
            package_ids.append(package_id)
        return package_ids

    def _create_task_for_deps(self, list_of_versionIds):
        for dependency in list_of_versionIds:
            task_options = {
                "command": f"package install --package {dependency}"
            }

            task = SFDXOrgTask(self.project_config,
                               TaskConfig({"options": task_options}),
                               self.org_config)
            task()
    
    def _query_dev_hub(self, package_name, version=None):
        query = f"SELECT {','.join(package_query_fields)} FROM Package2Version WHERE Package2.Name = '{package_name}'"
        self.logger.info(f"\nQuerying Dev Hub for package: {package_name}")
        self.logger.info(f"Query: {query}\n")
        result = self.tooling.query(query)
        arr = [PackageVersion(x) for x in result["records"]]
        sorted_arr = sorted(arr, key=lambda x: x.version)
        self.logger.info(f"Found Package Versions:\n{pp.pformat(sorted_arr)}")
        if version is not None:
            self.logger.info(f"Filtering for version: {version}")
            return [x for x in sorted_arr if x.version == version]
        return sorted_arr
    

    
    def _query_dependencies(self, package_version_id):
        self.logger.info(f"Querying dependencies for package version: {package_version_id}")
        query = f"SELECT Dependencies FROM SubscriberPackageVersion WHERE Id = '{package_version_id}'"
        self.logger.info(f"Query: {query}\n")
        result = self.tooling.query(query)
        results = [PackageDependency(r['Dependencies']) for r in result["records"]]
        return results
        # return [r['Ids'] for r in result["records"]]

        

    def _get_package_version_id(self, package_name, version="latest"):
        if package_name.startswith('04t'):
            return package_name
        if package_name in self.aliases:
            for alias in self.aliases:
                if self.aliases[alias].startswith('04t') and alias == package_name:
                    return self.aliases[alias]
        
        return None

    def _init_task(self):
        self.tooling = get_simple_salesforce_connection(
            self.project_config,
            get_devhub_config(self.project_config),
            api_version=self.project_config.project__package__api_version,
            base_url="tooling",
        )
        self.context = TaskContext(self.org_config, self.project_config, self.logger)

    def _get_package_from_packages(self, dependency):
        package_name = dependency["package"] if "package" in dependency else None
        if package_name is None:
            return None
        for package in self.packages:
            if package["package"] == package_name:
                return package
        return None
    
    def _query_only(self):
        versions = self._query_dev_hub(self.options["name"])        
        self.logger.info(f"Found Package Versions:\n{pp.pformat(versions)}")
        return versions
    
    def _get_deps_from_sfdx_project_package(self, package):
        deps = []
        self.logger.info(f"Getting dependencies for package: {package['package']}")
        if "dependencies" in package:
            self.logger.info(f"Found dependencies in sfdx-project.json {package['dependencies']}")
            for dep in package["dependencies"]:
                if "subscriberPackageVersionId" in dep:
                    deps.append(
                        PackageDependency(
                            {"ids": [
                                {"subscriberPackageVersionId": dep["subscriberPackageVersionId"]}
                                ]
                            })
                        )
                elif "package" in dep:
                    for found in self._query_dev_hub(dep["package"]):
                        deps.append(
                            PackageDependency(
                                {"ids": [
                                    {"subscriberPackageVersionId": found.SubscriberPackageVersionId}
                                    ]
                                })
                            )
                        deps += self._query_dependencies(found.SubscriberPackageVersionId)
                    return list(set(deps))
        else:
            self.logger.info("No dependencies found in sfdx-project for package")
        return deps

    def create_task(task_class, options=None, project_config=None, org_config=None):
        if options is None:
            options = {}
        task_config = TaskConfig({"options": options})
        return task_class(project_config, task_config, org_config)
            
    def _run_task(self):

        packageName = self.root_package["package"]
        rootSubscriberId = self._get_subscriber_package_id(packageName)

        self.logger.info(f"Getting dependencies for: {self.options["name"]}")
        if self.root_package is None:
            self.logger.info("Main Package Version not found in sfdx-project.json")
            return

        versions = self._query_only()
        if self.query_only:
            self.logger.info("Query only mode, not installing")
            return
        
        deps = []
        if len(versions) == 1:
            deps = self._query_dependencies(versions[0].SubscriberPackageVersionId)
            self.logger.info(f"Found Dependencies:\n{pp.pformat(deps)}")
        elif len(versions) > 1:
            self.logger.info("Multiple versions found, please specify a version")
        else:
            self.logger.info("No versions found for package in dev hub")
            # get deps from sfdx-project.json
            package = self._get_package_from_packages_by_name(self.options["name"], self.packages)
            if package is not None:
                deps = self._get_deps_from_sfdx_project_package(package)
        
        list_of_dep_ids = []
        for dep in deps:
            for ids in dep.ids:
                list_of_dep_ids.append(ids['subscriberPackageVersionId'])

        uniques = list(set(list_of_dep_ids))
        self._create_task_for_deps(uniques)
            
            return