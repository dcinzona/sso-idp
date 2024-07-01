/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class JitExtensions_TEST {

    @isTest
    static void RegistryTest() {
        JitExtensionRegistry registry = new JitExtensionRegistry();
        JitHandler jitHandler = new JitHandler();
        System.assertEquals(1, registry.extensions.size(), 'PermSetExtension not found');
        System.assertEquals(jitHandler.registry.extensions.size(), registry.extensions.size(), 'JitHandler.registry.extensions.size() != registry.extensions.size()');
    }
    @isTest
    static void PermSetExtensionTest() {
        JitExtensionRegistry registry = new JitExtensionRegistry();
        System.assertEquals(1, registry.extensions.size(), 'PermSetExtension not found');

        for (JitHandlerExtension ext : registry.extensions) {
            System.assertEquals(100, ext.sortOrder(), 'PermSetExtension sortOrder() != 100');
            ext.run();
        }
    }
}