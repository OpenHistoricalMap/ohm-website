# frozen_string_literal: true

require "application_system_test_case"

class SelectLanguageTest < ApplicationSystemTestCase
  test "can select language when logged out" do
    visit help_path

    within_content_heading do
      assert_text "Getting Help"
      assert_no_text "Obtenir de l’aide"
    end

    click_on "Select Language"

    assert_content "English"
    # Wait for the list frame to load (it focuses the input) before typing.
    find_by_id("language_search", :focused => true).set("fra").send_keys(:tab)

    within "#select_language_list" do
      assert_no_text "English"
    end

    click_on "français"

    within_content_heading do
      assert_no_text "Getting Help"
      assert_text "Obtenir de l’aide"
    end
  end

  test "can select language when logged in" do
    user = create(:user, :display_name => "LanguageTestUser")
    sign_in_as(user)

    visit help_path

    assert_no_text "Préférences mises à jour"
    within_content_heading do
      assert_text "Getting Help"
      assert_no_text "Obtenir de l’aide"
    end

    click_on "Select Language"

    assert_content "English"
    # Same wait as in the logged out test above.
    find_by_id("language_search", :focused => true).set("fra").send_keys(:tab)

    within "#select_language_list" do
      assert_no_text "English"
    end

    click_on "français"

    assert_text "Préférences mises à jour"
    within_content_heading do
      assert_no_text "Getting Help"
      assert_text "Obtenir de l’aide"
    end

    click_on "LanguageTestUser"
    click_on "Mes préférences"

    within_content_body do
      assert_select "Langue préférée", :selected => "français"
    end
  end
end
