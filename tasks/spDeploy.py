import os
import copy

from tasks.idpDeploy import Deploy
from cumulusci.utils import temporary_dir
from cumulusci.salesforce_api.utils import get_simple_salesforce_connection
deploy_options = copy.deepcopy(Deploy.task_options)
deploy_options["path"][
    "required"
] = False

METADATA_XML = """<?xml version="1.0" encoding="UTF-8"?>
<SamlSsoConfig xmlns="http://soap.sforce.com/2006/04/metadata">
    <executionUserId>{user_id}</executionUserId>
    <identityLocation>SubjectNameId</identityLocation>
    <identityMapping>FederationId</identityMapping>
    <issuer>{idp_org_url}</issuer>
    <loginUrl>{idp_org_url}/idp/endpoint/HttpRedirect</loginUrl>
    <name>Scratch Org IDP</name>
    <oauthTokenEndpoint>{sp_org_url}/services/oauth2/token</oauthTokenEndpoint>
    <redirectBinding>true</redirectBinding>
    <requestSignatureMethod>1</requestSignatureMethod>
    <requestSigningCertId>{cert_id}</requestSigningCertId>
    <salesforceLoginUrl>{sp_org_url}</salesforceLoginUrl>
    <samlEntityId>{sp_org_url}</samlEntityId>
    <samlJitHandlerId>{jit_apex_class}</samlJitHandlerId>
    <samlVersion>SAML2_0</samlVersion>
    <useConfigRequestMethod>true</useConfigRequestMethod>
    <useSameDigestAlgoForSigning>true</useSameDigestAlgoForSigning>
    <userProvisioning>true</userProvisioning>
    <validationCert>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
ozarc1gNimDP9sFmsq4bHvcm0m/uZXIHFA==
    </validationCert>
</SamlSsoConfig>"""

PACKAGE_XML = """<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>SamlSsoConfig</name>
    </types>
    <version>59.0</version>
</Package>"""


class deploySSO(Deploy):

    task_options = deploy_options
    api_version = None
    cert_id = None
    jit_hanlder = None

    def _init_task(self):
        super()._init_task()
        self.sf = self._init_api()
        self.tooling = self._init_api("tooling")

    def _init_api(self, base_url=None):
        rv = get_simple_salesforce_connection(
            self.project_config,
            self.org_config,
            api_version=self.api_version,
            base_url=base_url,
        )

        return rv

    def _init_options(self, kwargs):
        self.spOrgConfig = self.project_config.keychain.get_org('sp')
        self.idpOrgConfig = self.project_config.keychain.get_org('idp')
        self.idp_url = self.idpOrgConfig.instance_url
        self.sp_url = self.spOrgConfig.instance_url
        self.user_id = self.org_config.user_id[:15]
        super()._init_options(kwargs)

    def _get_cert_id(self, certName='SelfSignedCert') -> str | None:
        if self.cert_id:
            return self.cert_id
        # get the cert id from the org
        query = f"SELECT Id FROM Certificate WHERE DeveloperName = '{certName}' LIMIT 1"
        self.cert_id = self._get_record_id_from_query(query, self.tooling)
        return self.cert_id

    def _get_jit_class_id(self, name='JitHandler') -> str | None:
        if self.jit_hanlder:
            return self.jit_hanlder
        # get the cert id from the org
        query = f"SELECT Id FROM ApexClass WHERE Name = '{name}' LIMIT 1"
        self.jit_hanlder = self._get_record_id_from_query(query, self.tooling)
        return self.jit_hanlder

    def _get_record_id_from_query(self, query, api):
        for result in api.query_all(query)["records"]:
            return result["Id"][:15]
        self.logger.error(f"No results for query {query}")
        return None

    def _build_package(self):
        metapath = "samlssoconfigs"
        os.mkdir(metapath)
        metaxml = METADATA_XML.format(
            user_id=self.user_id,
            idp_org_url=self.idp_url,
            sp_org_url=self.sp_url,
            cert_id=self._get_cert_id(),
            jit_apex_class=self._get_jit_class_id()
        )
        with open(
            os.path.join(metapath, 'IdP' + ".samlssoconfig"),
            "w",
        ) as f:
            self.logger.info(f"{metapath}: {metaxml}")
            f.write(metaxml)
        with open("package.xml", "w") as f:
            f.write(PACKAGE_XML)

    def _run_task(self):
        with temporary_dir() as tempdir:
            self.tempdir = tempdir
            self._build_package()
            self.options["path"] = tempdir
            self.task_options["path"] = tempdir
            super()._run_task()
