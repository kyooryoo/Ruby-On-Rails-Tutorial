require 'test_helper'

class UsersEditTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end

  test "unsuccessful edit" do
    log_in_as(@user)
    # 确认在进入用户编辑页面后，基于编辑模版的页面生成
    get edit_user_path(@user)
    assert_template 'users/edit'
    # 确认在输入无效用户信息后，页面重新导航到编辑页面
    patch user_path(@user), params: { user: { name:  "",
                                              email: "foo@invalid",
                                              password:              "foo",
                                              password_confirmation: "bar" } }

    assert_template 'users/edit'
  end

  test "successful edit" do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    # 为测试有效编辑的结果这里提交合法的用户信息
    name  = "Foo Bar"
    email = "foo@bar.com"
    # 注意用户密码不必在每次更新中提交，以便用户可以只更新用户名和邮箱
    patch user_path(@user), params: { user: { name:  name,
                                              email: email,
                                              password:              "",
                                              password_confirmation: "" } }
    # 确认闪信不为空，因为应该会有更新成功的提示
    assert_not flash.empty?
    # 确认页面重定向到用户简介查看页面
    assert_redirected_to @user
    # 确认用户信息在数据库中也得到更新
    @user.reload
    assert_equal name,  @user.name
    assert_equal email, @user.email
  end

  test "successful edit with friendly forwarding" do
    get edit_user_path(@user)
    log_in_as(@user)
    assert_redirected_to edit_user_url(@user)
    assert_equal session[:forwarding_url], nil
    name  = "Foo Bar"
    email = "foo@bar.com"
    patch user_path(@user), params: { user: { name:  name,
                                              email: email,
                                              password:              "",
                                              password_confirmation: "" } }
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert_equal name,  @user.name
    assert_equal email, @user.email
  end
end