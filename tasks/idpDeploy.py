import os

from cumulusci.tasks.salesforce import Deploy
from cumulusci.utils import temporary_dir

CONNECTED_APP = """<?xml version="1.0" encoding="UTF-8"?>
<ConnectedApp xmlns="http://soap.sforce.com/2006/04/metadata">
    <contactEmail>{email}</contactEmail>
    <label>{label}</label>
    <oauthConfig>
        <callbackUrl>http://localhost:8080/callback</callbackUrl>
        <consumerKey>{client_id}</consumerKey>
        <consumerSecret>{client_secret}</consumerSecret>
        <scopes>Web</scopes>
        <scopes>Full</scopes>
        <scopes>RefreshToken</scopes>
    </oauthConfig>
</ConnectedApp>"""

PACKAGE_XML = """<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>ConnectedApp</name>
    </types>
    <version>44.0</version>
</Package>"""


class deployMetadata(Deploy):

    def _init_task(self):
        super()._init_task()
        self.spOrgId = self.project_config.keychain.get_org('sp').org_id
        self.idpOrgId = self.project_config.keychain.get_org('idp').org_id
        self._init_class()

    def _build_package(self):
        connected_app_path = "connectedApps"
        os.mkdir(connected_app_path)
        with open(
            os.path.join(connected_app_path, self.options["label"] + ".connectedApp"),
            "w",
        ) as f:
            f.write(
                CONNECTED_APP.format(
                    label=self.options["label"],
                    email=self.options["email"]
                )
            )
        with open("package.xml", "w") as f:
            f.write(PACKAGE_XML)

    def _run_task(self):
        with temporary_dir() as tempdir:
            self.tempdir = tempdir
            self._build_package()
            self.options["path"] = tempdir
            super()._run_task()
