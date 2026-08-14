# frozen_string_literal: true

require "application_system_test_case"

class AccountPdDeclarationTest < ApplicationSystemTestCase
  def setup
    @user = create(:user, :display_name => "test user")
    sign_in_as(@user)
  end

  # OHM variant: contributions must be in the Public Domain so we've removed
  #   test "can decline declaration if no declaration was made"
  # and
  #   test "can confirm declaration if no declaration was made"
  #
  # We've renamed this one & removed `@user.update(:consider_pd => true)`
  test "show disabled checkbox & button since contributions must be in the Public Domain" do
    visit account_pd_declaration_path

    within_content_body do
      assert_checked_field "I consider my contributions to be in the Public Domain", :disabled => true
      assert_button "Confirm", :disabled => true
    end
  end
end
