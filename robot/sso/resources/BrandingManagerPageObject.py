from cumulusci.robotframework.pageobjects import BasePage, pageobject

object_manager = {
    "button": "//input[@title='{}']",
    "input": "//input[@id='{}']",
    "select_related": "//select[@id = '{}']",
    "select_related_option": "//select[@id = 'DomainEnumOrId']/option[@value='{}']",
    "search_result": "//section[@class='related-list-card']//a[.=\"{}\"]",
    "formula_txtarea": "//textarea[@id = '{}']",
    "object_result": "//th/a[text()='{}']",
    "link-text": "//a[contains(text(),'{}')]",
    "button-with-text": "//button[contains(text(),'{}')]",
    "frame_new": "//iframe[contains(@name, '{}') or contains(@title, '{}')]",
    "action_menu": "//*[@id='setupComponent']//tr//td[@data-label='Developer Name' and @data-cell-value='{}']/..//lightning-button-menu",
    "action_menu_item": "//*[@id='setupComponent']//lightning-menu-item//a[text()='{}']",
    "activate_menu_item": "//*[@id='setupComponent']//td[@data-label='Developer Name' and @data-cell-value='{}']/..//lightning-menu-item//span[text()='Activate']/..",
    "activate_button": "//*[@id='setupComponent']//one-setup-actions-ribbon//lightning-button/button[@name='Activate']",
    "delete_confirm_btn": "//button[contains(@class,'forceActionButton')]",
}

# All common elements
search_button = object_manager["input"].format("globalQuickfind")
currency_locator = object_manager["input"].format("dtypeC")
next_button = object_manager["button"].format("Next")
save_button = object_manager["button"].format("Save")
text_locator = object_manager["input"].format("dtypeS")
formula_locator = object_manager["input"].format("dtypeZ")
checkbox_option = object_manager["input"].format("fdtypeB")
formula_txtarea = object_manager["formula_txtarea"].format("CalculatedFormula")
check_syntax = object_manager["button"].format("Check Syntax")
actions_menu = object_manager["action_menu"]
action_item_delete = object_manager["action_menu_item"].format("Delete")
confirm_delete = object_manager["delete_confirm_btn"]
lookup_locator = object_manager["input"].format("dtypeY")
activate_button = object_manager["activate_button"]


@pageobject(page_type="BrandingManager")
class BrandingManagerPage(BasePage):
    """A page object representing the Object Manager of an object.
    Example
    | Go to page   Setup  BrandingManager
    """

    def _go_to_page(self):
        object_name = self.object_name
        if object_name != "home":
            object_name = object_name + '/view'
        url_template = "{root}/lightning/setup/ThemingAndBranding/{id}"
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, id=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        if object_name != "home":
            self.selenium.wait_until_page_contains_element(activate_button)
            self.salesforce._jsclick(activate_button)
        self.builtin.sleep(3)
