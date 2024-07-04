import copy
from logging import root
from math import e
from struct import pack
from cumulusci.tasks.salesforce.install_package_version import InstallPackageVersion
from cumulusci.core.config import TaskConfig
from cumulusci.core.config.org_config import OrgConfig
from cumulusci.tasks.sfdx import SFDXBaseTask, SFDXOrgTask
from cumulusci.tasks.salesforce import BaseSalesforceApiTask

install_options = copy.deepcopy(InstallPackageVersion.task_options)
install_options["name"]["required"] = True
install_options["namespace"]["required"] = False

# cci task run dx --command "package install --package 'identity-common'" --org idp

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
    }
    root_package = None
    packages = None

    def _init_options(self, kwargs):
        super()._init_options(kwargs)
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

    def _create_task_for_deps(self, dependencies):
        for dependency in dependencies:
            task_options = {
                "command": "package install",
                "extras": "--package " + dependency["subscriberPackageId"],
            }
            task = self.create_task(
                SFDXOrgTask,
                task_options,
                project_config=self.project_config,
                org_config=self.org_config
            )
            task()

    def _run_task(self):
        self.logger.info(f"Installing package: {self.options["name"]}")
        if self.root_package is None:
            self.logger.info("Package not found in sfdx-project.json")
            return
        root_package_name = self.root_package["package"]
        dependencies = self._get_dependencies_for_package(root_package_name)
        for dependency in dependencies:
            self.logger.info(f"Found dependency: {dependency}")
        
