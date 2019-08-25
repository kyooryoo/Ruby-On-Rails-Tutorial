# Ruby on Rails 教程 - 样例程序

该样例程序来自
[*Ruby on Rails 教程*](https://www.railstutorial.org/)

## 授权
MIT 和 Beerware License.

## 开始
克隆代码库，安装GEM库，迁移数据库，测试，运行程序
```
$ bundle install --without production
$ rails db:migrate
$ rails test
$ rails server
```

详情
[*Ruby on Rails Tutorial* 原书](https://www.railstutorial.org/book).

## 之前的部分我会慢慢补上，有时间也会为各章节分别建立文件夹
## 现在暂时从第十章开始，总共十四个章节

## 第十章 更新、列印和删除用户

官方教程：https://www.railstutorial.org/book/updating_and_deleting_users

本节完成用户资源的其他REST动作，添加包括编辑、更新、列印和删除操作。
1. 添加允许用户修改自身简介的功能，同时强制对该操作开启认证授权。
2. 添加列印用户的功能，涉及到抽样数据和分页，同样需要强制授权。
3. 添加删除用户的功能，通过建立一个高权限的管理员用户类来执行。

## 切换到本地开发环境

之前使用的云端IDE是Cloud9，建立在AWS的虚拟机上。从现在开始迁移开发环境到本地，转移代码库到GitHub。

首先，检查本地的环境对ruby、rails、和git是否就绪。如有没就绪项，可自行搜索或根据系统提示完成安装。接着从BitBucket克隆项目文档库到本地，并上传到GitHub。最后，尝试运行rails服务器，系统会提示运行bundle安装命令。

注意，由于生产环境中配置的pg数据库在本地开发和测试中不会使用，安装反而还会遇到问题，所以在bundle安装中可以配置参数跳过生产环境的库安装。此时运行rails服务器不会报错，但导航到程序页面会遇到错误提示，需要根据提示做数据库迁移。终止rails服务器，迁移数据库，再重新运行rails数据库即可。

## 更新用户

编辑用户信息的方式与创建新用户类似，只是用`edit`动作而不是`new`动作生成用户视图，用`update`响应`PATCH`请求而不是用`create`响应`POST`请求。最主要的区别是，虽然任何人都可以注册，但只有当前用户才能修改自己的简介。这里将会用`before filter`，即一个提前过滤功能实现对用户的登录状态验证。

```
# 首先创建本节的代码分支
$ git checkout -b updating-users
```

### 编辑表单

为了启用用户简介编辑视图页面，需要通过在用户控制器添加`edit`动作和在用户视图中添加`edit`视图。这里，先添加`edit`动作，从数据库中拿到相关的用户，编辑用户简介的页面URL地址为`/users/<user_id>/edit`。用户ID的`user_id`变量可以通过`params[:id]`引用，更新用户控制器添加`edit`动作如下：
更新的文件：app/controllers/users_controller.rb
```
class UsersController < ApplicationController
  ...
  # 新增代码开始
  def edit
    @user = User.find(params[:id])
  end

  private
  ...
end
```

创建用户的`edit`视图文件：
app/views/users/edit.html.erb
```
<% provide(:title, "Edit user") %>
<h1>Update your profile</h1>

<div class="row">
  <div class="col-md-6 col-md-offset-3">
    <%= form_for(@user) do |f| %>
      <%= render 'shared/error_messages' %>

      <%= f.label :name %>
      <%= f.text_field :name, class: 'form-control' %>

      <%= f.label :email %>
      <%= f.email_field :email, class: 'form-control' %>

      <%= f.label :password %>
      <%= f.password_field :password, class: 'form-control' %>

      <%= f.label :password_confirmation, "Confirmation" %>
      <%= f.password_field :password_confirmation, class: 'form-control' %>

      <%= f.submit "Save changes", class: "btn btn-primary" %>
    <% end %>

    <div class="gravatar_edit">
      <%= gravatar_for @user %>
      <a href="http://gravatar.com/emails" target="_blank">change</a>
    </div>
  </div>
</div>
```

更新导航下拉链接项目
`app/views/layouts/_header.html.erb`
```
# 更新的部分
<li><%= link_to "Settings", edit_user_path(current_user) %></li>
```

这部分有两个残留问题，一是用户简介页面用户头像超链接打开的是一个外部资源，目前的代码中存在安全隐患。二是用户简介和用户注册页面存在代码冗余，即用户信息的表单部分，可以提取出来作为单独的代码片段。

第一个问题：
```
# 原始的链接定义如下，存在安全和性能隐患，具体参考备注部分关于`rel="noopener"`的说明
<a href="http://gravatar.com/emails" target="_blank">change</a>
# 如下添加超链接的`rel="noopener"`属性定义后，可以排除安全和新能隐患
<a href="http://gravatar.com/emails" target="_blank" rel="noopener">change</a>
```

第二个问题：
新建表单代码片段`app/views/users/_form.html.erb`:
```
<%= form_for(@user) do |f| %>
  <%= render 'shared/error_messages', object: @user %>

  <%= f.label :name %>
  <%= f.text_field :name, class: 'form-control' %>

  <%= f.label :email %>
  <%= f.email_field :email, class: 'form-control' %>

  <%= f.label :password %>
  <%= f.password_field :password, class: 'form-control' %>

  <%= f.label :password_confirmation %>
  <%= f.password_field :password_confirmation, class: 'form-control' %>

  # 注意这里的表单按钮名称由外部变量填充
  <%= f.submit yield(:button_text), class: "btn btn-primary" %>
<% end %>
```

更新新建用户的视图文件，引用抽取的表单代码片段：
`app/views/users/new.html.erb`:
```
<% provide(:title, 'Sign up') %>
# 添加如下语句为外部表单组件提供按钮名称参数
<% provide(:button_text, 'Create my account') %>
<h1>Sign up</h1>
<div class="row">
  <div class="col-md-6 col-md-offset-3">
    <%= render 'form' %>
  </div>
</div>
```

更新编辑用户信息的视图文件，引用抽取的表单代码片段：
`app/views/users/edit.html.erb`:
```
<% provide(:title, 'Edit user') %>
# 添加如下语句为外部表单组件提供按钮名称参数
<% provide(:button_text, 'Save changes') %>
<h1>Update your profile</h1>
<div class="row">
  <div class="col-md-6 col-md-offset-3">
    <%= render 'form' %>
    <div class="gravatar_edit">
      <%= gravatar_for @user %>
      <a href="http://gravatar.com/emails" target="_blank">Change</a>
    </div>
  </div>
</div>
```

注意，使用外部代码片段时，可以从调用代码片段的页面传递参数到代码片段中去：
```
# 调用代码片段的页面中，用`provide`在头部定义将要传递的参数
<% provide(:button_text, 'Create my account') %>
# 代码片段中，用`yield`提取传入的参数值
<%= f.submit yield(:button_text), class: "btn btn-primary" %>
```

### 编辑失败

编辑失败的处理与注册失败的处理方式类似，流程如下：
1. 创建`update`动作，使用提交的参数尝试更新用户。
2. 更新成功的后续再议，更新失败则返回`false`。
3. 如果更新失败则重新跳转到编辑页。

更新用户控制器，实现以上编辑用户简介的逻辑：
`app/controllers/users_controller.rb`:
```
# 在之前添加的edit方法之后添加如下方法
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      # Handle a successful update.
    else
      render 'edit'
    end
  end
```

### 测试编辑失败

测试编辑失败时的流程，生成集成测试的文件：
```
$ rails generate integration_test users_edit
```

更新文件用户编辑操作的集成测试场景：
`test/integration/users_edit_test.rb`:
```
require 'test_helper'

class UsersEditTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end

  test "unsuccessful edit" do
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), params: { user: { name:  "",
                                              email: "foo@invalid",
                                              password:              "foo",
                                              password_confirmation: "bar" } }

    assert_template 'users/edit'
  end
end
```

以上测试验证用户编辑页面可以正确显示，在传递无效参数造成编辑失败的情况下会重新导航到编辑页面。

运行测试，检验结果：
```
$ rails test
```

### 编辑成功

使用测试驱动开发的TDD方法，先完成测试代码，设计编辑成功情况下的流程：
1. 导航到用户简介编辑页面，确认页面模版显示正确。
2. 使用有效参数更新用户简介。
3. 确认闪信不为空，且页面重定向到用户简介页面。
4. 重载页面，确认用户名和邮箱显示正确。

更新编辑用户的集成测试：
`test/integration/users_edit_test.rb`
```
  # 添加如下编辑成功时的测试场景
  test "successful edit" do
    get edit_user_path(@user)
    assert_template 'users/edit'
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
```

更新用户控制器：
`app/controllers/users_controller.rb`中对`update`动作的定义：
```
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      # 更新添加以下两行代码
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end
```
以上更新在成功编辑用户简介后闪信确认，并重定向页面到用户简介页面。

更新用户模型：
`app/models/user.rb`
```
validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
```
以上主要更新密码长度的定义，添加了条件`allow_nil: true`，即允许空白密码。

这里不用担心密码为空会允许用户使用空密码注册，因为之前有`has_secure_password`的限定条件会对新用户注册的密码做检查，而`validates :password`只会对用户更改的信息有效，不会影响新用户注册的条件检查。

运行测试`rails test`，验证可以通过。

## 用户授权

认证识别用户，授权限制权限。目前，任何用户，甚至没有登录的用户，都可以访问和更新已有用户的信息，这里我们实施的安全模型将限制只有登录用户可以修改自己的信息。

设想存在如下场景：
* 未登录用户，试图访问需要授权的页面，如用户简介编辑页面，系统会跳转到登录页面并给出帮助信息。
* 任意用户，试图访问无权访问的页面，如已登录用户访问其他用户的简介修改页面，系统会跳转到网站主页。

### 需要登录的用户

为增加对指定动作的登录前提要求，在控制器中增加前提过滤设置，强制在触发某些控制器动作前先执行某些指定方法。注意，如果不指定控制器动作，前提过滤会应用到控制器中的全部动作。

更新用户控制器，添加如下代码：
`app/controllers/users_controller.rb`：
```
class UsersController < ApplicationController
  # 在触发edit或update动作前先执行指定的logged_in_user方法
  before_action :logged_in_user, only: [:edit, :update]
  ...
  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end

    # 确认用户登录状态
    def logged_in_user
      # 如果没有登录，闪信通知用户登录并跳转页面到登录页面
      unless logged_in?
        flash[:danger] = "Please log in."
        redirect_to login_url
      end
    end
end
```

此时运行测试会遇到错误，因为关于用户编辑的集成测试中没有指定用户登录，更新编辑用户简介的集成测试：
`test/integration/users_edit_test.rb`：
```
  test "unsuccessful edit" do
    # 添加以下要求登录的条件语句
    log_in_as(@user)
    get edit_user_path(@user)
    ...
  end

  test "successful edit" do
    # 添加以下要求登录的条件语句
    log_in_as(@user)
    get edit_user_path(@user)
    ...
  end
```

此时回去，注释掉用户控制器中的`before_action`语句，再次运行测试，依然可以通过。这相当于关于编辑和更新动作的强制登录设置缺失时没有测试出来，为了测试出这个安全漏洞，更新用户控制器测试定义文件：
`est/controllers/users_controller_test.rb`
```
  def setup
    @user = users(:michael)
  end

  ...

  test "should redirect edit when not logged in" do
    get edit_user_path(@user)
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "should redirect update when not logged in" do
    patch user_path(@user), params: { user: { name: @user.name,
                                              email: @user.email } }
    assert_not flash.empty?
    assert_redirected_to login_url
  end
```
更新用户控制器测试，是因为测试目标前提过滤器`before filter`针对控制器动作哦而设置。这里测试场景设计如下：
* 未登录用户访问用户简介编辑页面，确认闪信内容不为空，页面重定向到登录页
* 未登录用户尝试更新用户简介，确认闪信内容不为空，页面重定向到登录页

此时注释掉用户控制器中的前提过滤器，运行测试，确认可以检测出以上刚定义的两处错误场景。反注释掉前提过滤器，再去运行测试，依然可以通过。

### 需要正确的用户

不仅是只有登录用户可以编辑简介，且只能编辑登录用户自己的简介。为了开发这部分功能，依据测试驱动开发的TDD操作流程，先要写出测试不同用户间不可互相编辑的测试场景，为此需要准备一个新的测试用户账户，更新测试用用户样本数据：
`test/fixtures/users.yml`
```
...
# 这里添加除了michael以外的第二个用户
archer:
  name: Sterling Archer
  email: duchess@example.gov
  password_digest: <%= User.digest('password') %>
```

更新用户控制器测试定义文件，添加对新增测试用户的引用，以及非本人用户尝试编辑和更新其他用户简介的场景：
```
  def setup
    @user       = users(:michael)
    # 增加对新建测试用户的引用
    @other_user = users(:archer)
  end

  ...

  test "should redirect edit when logged in as wrong user" do
    # 测试登录用户访问他人简介编辑页面
    log_in_as(@other_user)
    get edit_user_path(@user)
    # 验证闪信信息不为空，页面跳转到主页
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should redirect update when logged in as wrong user" do
    log_in_as(@other_user)
    patch user_path(@user), params: { user: { name: @user.name,
                                              email: @user.email } }
    assert flash.empty?
    assert_redirected_to root_url
  end
```
当然，当前的测试结果是失败的，因为相关的功能还没有实施。

更新用户控制器文件，将尝试编辑他人简介的用户重定向到网站主页，
`app/controllers/users_controller.rb`
```
class UsersController < ApplicationController
  before_action :logged_in_user, only: [:edit, :update]
  # 新增如下语句，为eidt和update动作添加correct_user的条件
  before_action :correct_user,   only: [:edit, :update]
  ...
  def edit
    # 因为correct_user在此动作前已经执行且定义了用户变量，这里就省略了
    # @user = User.find(params[:id])
  end

  def update
    # 同上
    # @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end
  ...
  private
    ...
    # Confirms the correct user.
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless @user == current_user
    end
end
```
这里创建一个`correct_user`动作。注意到新创建的`correct_user`动作中有用户变量`@user = User.find(params[:id])`的定义，且该方法通过`before_action`过滤器在`edit`和`update`动作前已经执行，所以后面代码中`edit`和`update`动作里声明用户变量的声明可以省略。

此时再次进行测试，可以确认所有测试项目通过。

这里再追加一个帮助方法`current_user?(user)`，用来确认指定用户是否为当前登录用户:
`app/helpers/sessions_helper.rb`
```
  ...
  # 如果指定用户是当前登录用户则返回真
  def current_user?(user)
    user == current_user
  end

  def current_user
  ...
```

在用户控制器中使用该帮助方法，即用`current_user?(@user)`代替`@user == current_user`:
`app/controllers/users_controller.rb`
```
    def correct_user
      @user = User.find(params[:id])
      # redirect_to(root_url) unless @user == current_user
      redirect_to(root_url) unless current_user?(@user)
    end
```

## 友好跳转

目前，如果未登录用户试图访问任何未授权页面，网站会跳转到登录页。而当该用户登录后，网页会跳转到该用户的简介页面，却不是该用户之前想要访问的页面。更理想和友好的方式是在用户登录后跳转到之前他原本打算要打开的页面，如果有那样的页面。

遵循测试驱动开发TDD的流程，先写出理想场景下的逻辑测试代码：
`test/integration/users_edit_test.rb`
```
  test "successful edit with friendly forwarding" do
    # 更新添加以下三条语句
    get edit_user_path(@user)
    log_in_as(@user)
    assert_redirected_to edit_user_url(@user)
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
```
以上测试更新添加的三条语句模拟如下流程：
1. 尝试导航到用户简介编辑页，实际不会成功。
2. 之后成功登录，网站会导航到之前尝试打开的用户简介编辑页面。
3. 最后确认的确导航到了用户简介编辑页。

为了实现在登录后导航回登录前页面的功能，在会话帮助文件中定义两个方法：
* `store_location`用于保存用户登录前所在的目标页面
* `redirect_back_or`用于在登录后导航用户回到最初目标页面

更新会话帮助文件：
`app/helpers/sessions_helper.rb`:
```
  # Redirects to stored location (or to the default).
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # Stores the URL trying to be accessed.
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
```
注意，以上语句中保存URL地址使用的是`session[:var]`方法，而请求地址是从`request`对象的属性中提取，这里只限于对GET请求有效。这里的`if request.get?`确认在使用`GET`方法时才返回请求的地址，因为用户可以使用其他HTTP方法例如`POST`，`PATCH`或`DELETE`等方法在没有登录的情况下提交表单，而这样的场景下使用默认GET方法返回原始请求页面会引发错误。

另外，重定向登录用户的`redirect_back_or`方法在重定向后清除了`session[:forwarding_url]`变量值，这是为了防止以后的用户登录后，在没有前序访问页面之前，会被导航到前一个用户指定的重定向页面，而无法进入`default`页面。另外，虽然清除`session[:forwarding_url]`变量值的语句在页面跳转`redirect_to()`之后，但这并不妨碍前者的运行，因为在遇到`return`或者`end`语句之前跳转不会实际发生。

更新用户控制器，在提示用户登录和跳转到登录页面之前保存用户想要访问的页面地址：
`app/controllers/users_controller.rb`
```
    def logged_in_user
      unless logged_in?
        # 只需要添加如下一条语句
        store_location
        flash[:danger] = "Please log in."
        redirect_to login_url
      end
    end
```

更新会话控制器，在新的登录会话创建后跳转到用户登录之前想要访问的页面：
`app/controllers/sessions_controller.rb`
```
  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      log_in user
      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
      # 这里只需要添加入下一行语句
      redirect_back_or user
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end
```

测试，确认可以通过。

### 追加测试

添加`session[:forwarding_url]`变量值的清理确认，即用户登录和跳转到原始的请求页面后，保存原始请求链接的变量应该是空的，否则以后其他用户登录后还会重定向到该页面。更新用户简介编辑测试：
`test/integration/users_edit_test.rb`
```
  test "successful edit with friendly forwarding" do
    get edit_user_path(@user)
    log_in_as(@user)
    assert_redirected_to edit_user_url(@user)
    # 这里需要添加的测试语句仅此如下一行
    assert_equal session[:forwarding_url], nil
    ...
  end
```

如果你也有`debugger`的问题，而且错误提示有`readline`，可以尝试先后重新安装`readline`和`ruby`：
```
$ brew install readline
$ rvm list known
$ rvm install 2.6.3
$ gem install rails 
```
以上修复完成后，在`debugger`终端中的输入仍不可见，也就是不知道输入了什么，但只要输入正确可以得到期待的结果。

## 列印用户

这部分创建用户主页，也就是`index`动作，显示所有用户。从数据库中获取用户信息并分页显示，以应对用户数量较多的情况，为管理员准备删除用户的界面。

设想的场景是，单个用户的简介页面对所有人开放，包括未登录用户，但显示所有用户的页面将只对注册用户开放，所以这里先要实施一个安全功能，依然按照测试驱动开发的TDD流程，先写出测试场景，更新用户控制器测试：
`test/controllers/users_controller_test.rb`
```
  test "should redirect index when not logged in" do
    get users_path
    assert_redirected_to login_url
  end
```

在用户控制器中定义`index`动作，显示所有用户，并指定对登录用户开放访问：
`app/controllers/users_controller.rb`
```
  # 以下更新将index动作放入登录用户的过滤器中，非登录用户不得查看
  before_action :logged_in_user, only: [:index, :edit, :update]
  ...
  # 目前获取全部用户，放入`@user`变量并传递给`index`视图
  def index
    @users = User.all
  end
```

创建`index`视图，使用`each`方法遍历每个用户并生成一个`li`对象：
`app/views/users/index.html.erb`
```
<% provide(:title, 'All users') %>
<h1>All users</h1>
<ul class="users">
  <% @users.each do |user| %>
    <li>
      <%= gravatar_for user, size: 50 %>
      <%= link_to user.name, user %>
    </li>
  <% end %>
</ul>
```

以上用户列表中显示用户头像的自定义方法`gravatar_for`来自用户帮助方法：
`app/helpers/users_helper.rb`
```
module UsersHelper
  def gravatar_for(user, options = { size: 80 })
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url, alt: user.name, class: "gravatar")
  end
end
```

添加对用户列表的格式定义：
`app/assets/stylesheets/custom.scss`
```
/* Users index */

.users {
  list-style: none;
  margin: 0;
  li {
    overflow: auto;
    padding: 10px 0;
    border-bottom: 1px solid $gray-lighter;
  }
}
```

将用户列表页面的链接添加到网站头部导航栏：
`app/views/layouts/_header.html.erb`
```
<header class="navbar navbar-fixed-top navbar-inverse">
  <div class="container">
    <%= link_to "sample app", root_path, id: "logo" %>
    <nav>
      <ul class="nav navbar-nav navbar-right">
        <li><%= link_to "Home", root_path %></li>
        <li><%= link_to "Help", help_path %></li>
        <% if logged_in? %>
          # 这里需要更新的代码仅只以下一行
          <li><%= link_to "Users", users_path %></li>
          <li class="dropdown">
            <a href="#" class="dropdown-toggle" data-toggle="dropdown">
              Account <b class="caret"></b>
            </a>
            <ul class="dropdown-menu">
              <li><%= link_to "Profile", current_user %></li>
              <li><%= link_to "Settings", edit_user_path(current_user) %></li>
              <li class="divider"></li>
              <li>
                <%= link_to "Log out", logout_path, method: :delete %>
              </li>
            </ul>
          </li>
        <% else %>
          <li><%= link_to "Log in", login_path %></li>
        <% end %>
      </ul>
    </nav>
  </div>
</header>
```

测试，验证结果通过测试场景，并打开网页验证。


### 用户样本

Rails允许使用程序自动生成大量样本用户，以满足开发和测试需要。

更新`Gemfile`文件，添加`faker`到所有环境，至少开发环境：
`Gemfile`
```
gem 'faker', '1.7.3'
```

运行`bundle install`安装更新的库:
```
$ bundle install
```

更新数据库种子文件：
`db/seeds.rb`
```
User.create!(name:  "Example User",
             email: "example@example.com",
             password:              "password",
             password_confirmation: "password")

99.times do |n|
  name  = Faker::Name.name
  email = "example-#{n+1}@example.com"
  password = "password"
  User.create!(name:  name,
               email: email,
               password:              password,
               password_confirmation: password)
end
```
注意这里使用的`User.create!()`方法会在执行失败时产生一个异常，而不是返回`false`，以便调试和排错，并防止错误在悄无声息中发生。

重置数据库并生成样例用户，如果重置数据库失败，终止Rails服务器后再尝试：
```
$ rails db:migrate:reset
$ rails db:seed
```

现在可以运行Rails服务器，登录并到用户列表页面查看效果。所有用户显示在一个页面上，在用数量过多时会有加载时间过长和不便查看的问题，以下会通过分页用户显示列表解决。

### 分页用户

用`will_paginate`实现用户列表分页，更新库引用：
`Gemfile`
```
# 添加如下两行代码
gem 'will_paginate',           '3.1.6'
gem 'bootstrap-will_paginate', '1.0.0'
```

安装追加的库：
```
$ bundle install
```

重启Rails服务器，确保所有库正确加载。
更新用户的`index`视图，添加`will_paginate`方法：
`app/views/users/index.html.erb`
```
<% provide(:title, 'All users') %>
<h1>All users</h1>
# 添加如下一行语句
<%= will_paginate %>
<ul class="users">
  <% @users.each do |user| %>
    <li>
      <%= gravatar_for user, size: 50 %>
      <%= link_to user.name, user %>
    </li>
  <% end %>
</ul>
# 添加如下一行语句
<%= will_paginate %>
```
目前这个视图还没有按照预期工作，因为还需要更新用户控制器的`index`方法。

测试调用`paginate`方法为结果分页：
```
$ rails console
> User.paginate(page:1)
> User.paginate(page:nil)
```

更新用户控制器中的`index`动作：
`app/controllers/users_controller.rb`
```
  def index
    @users = User.paginate(page: params[:page])
  end
```
具体分页的页面参数会由`will_paginate`方法从`index`视图拿到。

运行Rails服务器，登录并打开用户列表页面，确认分页效果。

### 测试列印

为测试用户列印效果，更新测试数据源：
`test/fixtures/users.yml`
```
...
lana:
  name: Lana Kane
  email: hands@example.gov
  password_digest: <%= User.digest('password') %>

malory:
  name: Malory Archer
  email: boss@example.gov
  password_digest: <%= User.digest('password') %>

<% 30.times do |n| %>
user_<%= n %>:
  name:  <%= "User #{n}" %>
  email: <%= "user-#{n}@example.com" %>
  password_digest: <%= User.digest('password') %>
<% end %>
```
`fixture`支持嵌入式Ruby，除了手动添加几个用户，其他可以使用模版生成.


生成测试文件：
```
$ rails generate integration_test users_index
```

更新测试文件：
`test/integration/users_index_test.rb`
```
require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end

  test "index including pagination" do
    # 登录并导航到用户列表
    log_in_as(@user)
    get users_path
    # 确认视图模版
    assert_template 'users/index'
    # 确认页面中有两个分页功能组件
    assert_select 'div.pagination', count: 2
    # 确认第一分页中每个用户记录的超链接中有用户名
    User.paginate(page: 1).each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
    end
  end
end
```

这里也可以进行反向测试，将用户列表界面中的分页模块注释掉，再次测试确认无法通过。
```
# 注释前
<%= will_paginate %>
# 注释后
<%#= will_paginate %>
```

### 局部优化

使用Rails的功能优化用户列表视图，首先用`render`将用户列表中的`li`对象抽取出来：
`app/views/users/index.html.erb`
```
<ul class="users">
  <% @users.each do |user| %>
    <%= render user %>
  <% end %>
</ul>
```

手动创建抽取出来的`user`代码片段：
`app/views/users/_user.html.erb`
```
<li>
  <%= gravatar_for user, size: 50 %>
  <%= link_to user.name, user %>
</li>
```

进一步简化，让Rails自己遍历用户数组`@users`并应用抽取的`user`代码片段：
`app/views/users/index.html.erb`
```
<ul class="users">
  <%= render @users %>
</ul>
```

完成以上改进后测试，确认程序没有问题。

## 删除用户

目标是在管理员看到的用户列表中，为每个用户添加带删除操作的链接，该链接对普通用户不可见。

### 更新模型

更新用户模型，添加一个识别管理员的布尔型逻辑属性`admin`:
```
$ rails generate migration add_admin_to_users admin:boolean
```

对于以上数据库迁移操作的详情，可以在迁移定义中确认：
`db/migrate/[timestamp]_add_admin_to_users.rb`
```
class AddAdminToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :admin, :boolean, default: false
  end
end
```
这里，手动加入`default:false`是为增强代码可读性，效果与默认的`nil`值相同。

实施迁移并更新数据库架构：
```
$ rails db:migrate
```

在Rails控制台中确认更新结果：
```
$ rails console
2.5.1 :001 > user=User.first
2.5.1 :002 > user.admin?
 => false 
2.5.1 :003 > user.toggle!(:admin)
 => true 
2.5.1 :004 > user.admin?
 => true 
```

更新DB的种子文件，初始化一个管理员用户：
`db/seeds.rb`
```
User.create!(name:  "Example User",
             email: "example@example.com",
             password:              "password",
             password_confirmation: "password",
             # 这里只需更新呢如下一条语句
             admin: true)

99.times do |n|
  name  = Faker::Name.name
  email = "example-#{n+1}@example.com"
  password = "password"
  User.create!(name:  name,
               email: email,
               password:              password,
               password_confirmation: password)
end
```

重置数据库，生成测试用户账户：
```
$ rails db:migrate:reset
$ rails db:seed
```

小心恶意用户可以用如下更新操作将普通用户提升为管理员：
```
patch /users/17?admin=1
```

查看用户控制器中对用户属性参数的限制，确认无法通过HTTP请求更新用户的管理员属性：
`app/controllers/users_controller.rb`
```
def user_params
  params.require(:user).permit(:name, :email, :password, :password_confirmation)
end
```

更新用户控制器测试，添加对管理员属性编辑的不可用验证：
`test/controllers/users_controller_test.rb`
```
  test "should not allow the admin attribute to be edited via the web" do
    # 使用普通用户登录
    log_in_as(@other_user)
    # 确认管理员属性为否
    assert_not @other_user.admin?
    # 尝试通过HTTP的PATCH请求更新普通用户管理员属性为是
    patch user_path(@other_user), params: {
                                    user: { password:              "password",
                                            password_confirmation: "password",
                                            admin: true } }
    # 确认管理员属性依然为否
    assert_not @other_user.admin?
  end
```

测试，确认可以通过。

### 删除动作

更新用户列表中的单用户代码块，为每个用户记录添加一个删除操作链接，只有管理员可见：
`app/views/users/_user.html.erb`
```
<li>
  <%= gravatar_for user, size: 50 %>
  <%= link_to user.name, user %>
  <% if current_user.admin? && !current_user?(user) %>
    | <%= link_to "delete", user, method: :delete,
                                  data: { confirm: "You sure?" } %>
  <% end %>
</li>
```

浏览器无法原生的发出DELETE请求，Rails使用JS模拟这个操作，因此如果用户的浏览器禁用了JS会导致该删除链接不可用。如果必须支持不允许JS的浏览器，妥协方案是使用表单发送POST请求模拟DELETE操作，这个话题参见备注。

更新用户控制器，添加删除动作，将其加入只允许登录用户操作的动作列表：
`app/controllers/users_controller.rb`
```
...
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  ...
  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end
```

对`destory`动作再多添加一层安全保证，确认只有管理员用户才能触发：
`app/controllers/users_controller.rb`
```
class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  # 添加如下一条过滤器
  before_action :admin_user,     only: :destroy
  ...
  private
    ...
    # 添加对过滤器条件admin_user的定义
    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end
end
```

### 测试删除

更新用户测试用户定义，设置管理员：
`test/fixtures/users.yml`
```
michael:
  name: Michael Example
  email: michael@example.com
  password_digest: <%= User.digest('password') %>
  # 增加如下一行语句
  admin: true
...
```

更新用户控制器测试，验证非管理员用户删除失败的场景：
`test/controllers/users_controller_test.rb`
```
  test "should redirect destroy when not logged in" do
    #  未登录用户尝试删除用户，不成功，重定向到登录页面
    assert_no_difference 'User.count' do
      delete user_path(@user)
    end
    assert_redirected_to login_url
  end

  test "should redirect destroy when logged in as a non-admin" do
    # 登录用户，尝试删除用户，不成功，重定向到根页面
    log_in_as(@other_user)
    assert_no_difference 'User.count' do
      delete user_path(@user)
    end
    assert_redirected_to root_url
  end
```

更新用户列印功能的集成测试，验证管理员可以删除用户的场景：
`test/integration/users_index_test.rb`
```
require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest

  def setup
    @admin     = users(:michael)
    @non_admin = users(:archer)
  end

  test "index as admin including pagination and delete links" do
    # 管理员登录，导航到用户列表，确认页面模版为index
    log_in_as(@admin)
    get users_path
    assert_template 'users/index'
    # 确认有分页模块，第一分页中每个用户记录的超链接里有用户名
    assert_select 'div.pagination'
    first_page_of_users = User.paginate(page: 1)
    first_page_of_users.each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
      # 确认管理员可以看到删除链接
      unless user == @admin
        assert_select 'a[href=?]', user_path(user), text: 'delete'
      end
    end
    # 执行一次删除用户操作，确认成功
    assert_difference 'User.count', -1 do
      delete user_path(@non_admin)
    end
  end

  test "index as non-admin" do
    # 非管理员用户登录，导航到用户列表页面，确认没有删除链接
    log_in_as(@non_admin)
    get users_path
    assert_select 'a', text: 'delete', count: 0
  end
end
```

运行测试，确认可以通过。

## 收尾

收尾本章节如下：
```
# GitHub part
$ git add -A
$ git commit -m "Finish user edit, update, index, and destroy actions"
$ git checkout master
$ git merge updating-users
$ git push
# Heroku part
$ rails test
$ git push <your_heroku_gitrepo>
$ heroku pg:reset DATABASE -a <your_heroku_appname> --confirm
$ heroku run rails db:migrate -a <your_heroku_appname>
$ heroku run rails db:seed -a <your_heroku_appname>
$ heroku restart -a <your_heroku_appname>
```

## 备注
1. 关于为超链接添加`rel="noopener"`属性的必要性，可以参考如下文档：

2. 本节开始将Rails部署到本地，运行`bundle install`安装依赖库时遇到如`pg`安装错误：
```
# 系统提示运行如下命令，但实际没有作用
$ gem install pg -v '0.20.0' --source 'https://rubygems.org/
# 运行以下命令可以完成pg的安装，之后rails server即可运行
$ brew install postgres
```
3. 处理完`pg`的安装问题后，还需要更新数据库，`rails server`才可以正常工作。
```
$ rails db:migrate
```
4. 之前在云端设置的测试用户信息与教程不一致，导致测试发生了错误，这里更新为原始教程内容，并顺带更新其他测试文件：
更新测试用户定义文件`test/fixtures/users.yml`
```
michael:
  name: Michael Example
  email: michael@example.com
  password_digest: <%= User.digest('password') %>
```
更新其他即成测试文件`test/integration/users_login_test.rb`中的测试用户引用
```
  def setup
    @user = users(:michael)
  end
```
更新测试帮助文件`test/helpers/sessions_helper_test.rb`中的测试用户设置:
```
  def setup
    @user = users(:michael)
    remember(@user)
  end
```
5. 在从`new`和`edit`的用户视图中将表单剥离出来后，测试会出现错误，注销如下测试项目即可：
更新测试文件`test/integration/users_signup_test.rb`:
```
assert_select 'form[action="/signup"]'
```
6. 不使用JS实现用户删除操作，参考如下文档：
https://www.railstutorial.org/book/updating_and_deleting_users#cha-10_footnote-14

## 第十一章 激活用户

这一部分添加基于邮箱的账户认证功能，确认用户对其用户名邮箱的实际控制。涉及关联激活令牌和摘要到用户账户，将带有激活令牌的链接通过邮件发送给用户，在用户点击该链接时激活其账户。同样的技术也会用在下一个章节，用于重制用户密码。为实现以上功能，将要创建用户激活资源，了解更多关于控制器、路由和数据库迁移的知识，当然还有通过Rails发送邮件的方法。

用户激活的操作逻辑与用户登录和登录状态记忆功能追加的过程类似，包括以下步骤：
1. 将初始化的用户放在“未激活”的状态
2. 在用户注册时生成激活令牌和摘要（即一个随机字符串和其哈希值）
3. 保存激活摘要到数据库（避免令牌被恶意用户从数据库获取后用于账户激活）
4. 发送邮件到用户，包含一个带有激活令牌和用户邮箱地址的链接
4. 当用户点击邮件中的链接，根据邮箱地址找到用户，通过认证摘要验证令牌有效
5. 如果用户通过认证，修改用户账户状态从“未激活”到“已激活”

由于以上操作与密码和记忆令牌有很多相似之处，我们可以重用`User.digest`和`User.new_token`等方法于账户激活：
* find by / string / digest / authentication
* email / password / password_digest / authenticate(password)
* id / remember_token		remember_digest / authenticated?(:remember, token)
* email / activation_token / activation_digest / authenticated?(:activation, token)
* email / reset_token / reset_digest / authenticated?(:reset, token)

下面，我们要建立资源和数据模型用于用户账户激活，添加一个邮件模块用于发送用户激活邮件，实施用户激活，包括一个通用的`authenticated?`方法。

### 账户激活资源

我们将为用户激活建模，将其作为一种资源，即便与`Active Record`模型没有关系，在用户模型中仍然将会添加相关的激活令牌和激活状态信息。因为账户激活是一种资源，我们将使用标准REST URL与其交互，使用激活链接修改用户的激活状态。标准REST操作默认使用PATCH请求在`update`动作上。因为激活链接通过邮件发出，涉及基于浏览器的鼠标点击操作，会产生GET请求而不是PATCH请求。因此这个设计上的限制条件意味着我们不可以使用`update`动作，但可以使用可以响应GET请求的`edit`动作。

这里先创建本节代码分支：
```
$ git checkout -b account-activation
```

类似用户和会话，用户激活资源的动作定义在用户激活控制器中，使用如下命令生成：
```
$ rails generate controller AccountActivations
```

生成邮件中的激活用URL的方法为：edit_account_activation_url(activation_token, ...)，因此需要为`edit`动作指定路径，为此更新路由设置文件：
`config/routes.rb`
```
Rails.application.routes.draw do
  ...
  # 只需要添加以下一条语句
  resources :account_activations, only: [:edit]
end
```
生成的URL路径和请求等相关信息如下：
```
HTTP Request: GET
URL: http://ex.co/account_activation/<token>/edit
Action: edit
Named route: edit_account_activation_url(token)
```

### 账户激活数据模型

激活令牌如果直接保存到数据库会带来安全隐患，恶意用户可以通过访问数据库获得激活令牌，激活用户，修改密码并使用新建并激活的用户身份访问应用。为防止此类安全问题，不在数据中直接保存激活令牌，而是保存通过哈希计算从令牌得到的摘要信息。

对用户模型做如下更新：
* 访问用户的激活令牌，使用命令：user.activation_token
* 认证用户，使用命令：user.authenticated?(:activation, token)
* 确认用户是否激活，使用命令：if user.activated?
* 添加一个记录激活时间的用户属性

添加的用户属性包括：
* activation_digest	/ string
* activated	/ boolean
* activated_at	/	date time

使用如下命令添加以上三个属性到用户模型：
```
$ rails generate migration add_activation_to_users \
> activation_digest:string activated:boolean activated_at:datetime
```
注意，以上命令是一条，需要连续输入或直接粘贴到终端运行，粘贴时第二行不要出现两个`>`符号，否则生成的数据迁移文件不完整。

编辑数据库迁移文件，指定激活属性默认为`否`：
`db/migrate/[timestamp]_add_activation_to_users.rb`
```
class AddActivationToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :activation_digest, :string
    # 修改以下一行，追加默认属性值设置
    add_column :users, :activated, :boolean, default: false
    add_column :users, :activated_at, :datetime
  end
end
```
如果不做特殊指定，以上激活状态属性默认为`nil`也会被系统判断为`false`，只是这里特别指定会更明确且易读。

发起数据库迁移，完成数据模型的更新：
```
$ rails db:migrate
```

更新用户模型：
`app/models/user.rb`
```
class User < ApplicationRecord
  # 更新和添加如下共计三条语句
  attr_accessor :remember_token, :activation_token
  before_save   :downcase_email
  before_create :create_activation_digest
  
  validates :name,  presence: true, length: { maximum: 50 }
  ...
  private

    # 新添加方法，将email地址转换为小写
    def downcase_email
      self.email = email.downcase
    end

    # 新添加方法，创建和赋值激活令牌与摘要
    def create_activation_digest
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
end
```
以上将新添加的两个方法设为私有，因为程序的最终用户不会直接用到这些方法。

更新数据库样本用户定义文件，将生成100个样本用户：
`db/seeds.rb`
```
User.create!(name:  "Example User",
             email: "example@railstutorial.org",
             password:              "foobar",
             password_confirmation: "foobar",
             admin:     true,
             # 添加如下两行代码，定义激活状态和时间
             activated: true,
             activated_at: Time.zone.now)

99.times do |n|
  name  = Faker::Name.name
  email = "example-#{n+1}@railstutorial.org"
  password = "password"
  User.create!(name:  name,
              email: email,
              password:              password,
              password_confirmation: password,
              # 如上
              activated: true,
              activated_at: Time.zone.now)
end
```
注意以上代码中使用了Rails内建的帮助方法`Time.zone.now`，可以返回当前时区的当前时间。

更新测试用户定义文件：
`test/fixtures/users.yml`
```
michael:
  name: Michael Example
  email: michael@example.com
  password_digest: <%= User.digest('password') %>
  admin: true
  # 如上
  activated: true
  activated_at: <%= Time.zone.now %>

archer:
  name: Sterling Archer
  email: duchess@example.gov
  password_digest: <%= User.digest('password') %>
  # 如上
  activated: true
  activated_at: <%= Time.zone.now %>

lana:
  name: Lana Kane
  email: hands@example.gov
  password_digest: <%= User.digest('password') %>
  # 如上
  activated: true
  activated_at: <%= Time.zone.now %>

malory:
  name: Malory Archer
  email: boss@example.gov
  password_digest: <%= User.digest('password') %>
  # 如上
  activated: true
  activated_at: <%= Time.zone.now %>

<% 30.times do |n| %>
user_<%= n %>:
  name:  <%= "User #{n}" %>
  email: <%= "user-#{n}@example.com" %>
  password_digest: <%= User.digest('password') %>
  # 如上
  activated: true
  activated_at: <%= Time.zone.now %>
<% end %>
```

重制数据库并生成样本用户：
```
$ rails db:migrate:reset
$ rails db:seed
```
完成操作后运行测试，验证到目前为止程序功能正常。

### 账户激活邮件

使用`Action Mailer`的电子邮件功能，通过用户控制器中的`create`方法发送带有激活链接的邮件。就像用控制器中的其他动作调用视图文件一样，邮件也是如此通过邮件控制器中定义的动作调用视图模版发送，模版中包含激活令牌和需要被激活的邮箱地址。

使用Rails自带功能生成`Mailer`模块，与生成控制器及其动作的方法相同，这里的`mailer`虽然不放在控制器文件夹中，但作用类似于控制器：
```
$ rails generate mailer UserMailer account_activation password_reset
```
这里除了`account_activation`也创建了`password_reset`方法，为了下一个章节添加重制密码功能使用。

定制生成的邮件应用，设置了：
`app/mailers/application_mailer.rb`
```
class ApplicationMailer < ActionMailer::Base
  # 更新如下一条代码
  default from: "noreply@example.com"
  layout 'mailer'
end
```

更新用户激活动作：
`app/mailers/user_mailer.rb`
```
class UserMailer < ApplicationMailer
  # 这里只需要更新以下方法
  def account_activation(user)
    @user = user
    mail to: user.email, subject: "Account activation"
  end
  # 下一章才会涉及下面的方法
  def password_reset
    @greeting = "Hi"
    mail to: "to@example.org"
  end
end
```

用嵌入式Ruby定制邮件的文本视图模版：
`app/views/user_mailer/account_activation.text.erb`
```
Hi <%= @user.name %>,
Welcome to the Sample App! Click on the link below to activate your account:
<%= edit_account_activation_url(@user.activation_token, email: @user.email) %>
```

用嵌入式Ruby定制邮件的HTML视图模版：
`app/views/user_mailer/account_activation.html.erb`
```
<h1>Sample App</h1>
<p>Hi <%= @user.name %>,</p>
<p>Welcome to the Sample App! Click on the link below to activate your account:</p>
<%= link_to "Activate", edit_account_activation_url(@user.activation_token,
                                                    email: @user.email) %>
```

以上代码中，最后一行将会生成如下URL地址：
`<base_url>/account_activations/<activation_token>/edit?email=<user_email>`
* <base_url>为Rails服务器的基础URL地址
* <activation_token>为`new_token`方法创建的兼容URL的base64格式字符串
* URL中?后的URL格式查询参数由原始参数中的`email: @user.email`代入

某些特殊符号在编码到URL中时需要做转换，例如`@`需要编码为`%40`，在Rails中有命令可以完成：
```
$ rails console
> CGI.escape('example@example.com')
=> "example%40example.com"
```

### 预览邮件

Rails提供特殊的URL预览邮件的发送结果，更新开发环境配置文件如下：
`config/environments/development.rb`
```
  # 以下配置项原始值为false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :test
  # 修改以下占位符为实际服务器地址，我的环境是`localhost:3000`
  host = 'example.com'
  # 在Cloud9的IDE环境使用如下配置，定义使用HTTPS协议
  # onfig.action_mailer.default_url_options = { host: host, protocol: 'https' }
  # 在本地的开发环境使用如下配置，定义使用HTTP协议
  config.action_mailer.default_url_options = { host: host, protocol: 'http' }
```

更新预览邮件的视图定义文件：
`test/mailers/previews/user_mailer_preview.rb`
```
  def account_activation
    user = User.first
    user.activation_token = User.new_token
    UserMailer.account_activation(user)
  end
```
以上更新将开发用样本数据库中的第一个用户，将其传递给生成邮件的相关方法。现在运行Rails服务器即可确认：
http://localhost:3000/rails/mailers/user_mailer/account_activation

### 邮件测试

更新默认的邮件测试文件：
`test/mailers/user_mailer_test.rb`
```
require 'test_helper'
class UserMailerTest < ActionMailer::TestCase
  test "account_activation" do
    # 调取测试样本用户，生成激活令牌，生成邮件实例
    user = users(:michael)
    user.activation_token = User.new_token
    mail = UserMailer.account_activation(user)
    # 确认邮件标题，接收人，发送人
    assert_equal "Account activation", mail.subject
    assert_equal [user.email], mail.to
    assert_equal ["noreply@example.com"], mail.from
    # 确认用户姓名、激活令牌、URL兼容格式的用户邮箱等包含在邮件正文中
    assert_match user.name,               mail.body.encoded
    assert_match user.activation_token,   mail.body.encoded
    assert_match CGI.escape(user.email),  mail.body.encoded
  end
end
```

更新测试环境配置，添加主机默认URL地址设置：
`config/environments/test.rb`
```
  config.action_mailer.delivery_method = :test
  # 添加如下一条配置语句，使用实际服务器地址替换占位符'example.com'
  config.action_mailer.default_url_options = { host: 'example.com' }
```

运行测试，确认到目前为止的代码没有问题。

### 更新用户创建动作

因为新用户注册后需要激活，用户控制器中的`create`动作定义也需要更新。

之前，新用户注册后直接登录并跳转到用户简介，现在因为额外的激活步骤要在注册后跳转到网站根页面。
`app/controllers/users_controller.rb`
```
  def create
    @user = User.new(user_params)
    if @user.save
      # 更新以下三条语句，发送激活邮件，显示闪信，重定向到根页面
      UserMailer.account_activation(@user).deliver_now
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render 'new'
    end
  end
```

由于以上修改，用户注册后不会跳转到简介页面，也不会立即自动登录，因此需要修改相应的测试文件：
`test/integration/users_signup_test.rb`
```
  test "valid signup information" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name:  "Example User",
                                         email: "user@example.com",
                                         password:              "password",
                                         password_confirmation: "password" } }
    end
    follow_redirect!
    # 这里注销以下两条语句，不再确认跳转到用户列表，也不再确认用户是否登录
    # assert_template 'users/show'
    # assert is_logged_in?
  end
```
运行测试，确保到目前为止的代码正常。

## 激活账户

目前已经正确生成了邮件，下面在用户激活控制器中加入`edit`动作用于激活用户。如惯例，根据TDD测试驱动开发的流程，先写出测试代码，通过测试后再进行优化，将部分功能从账户激活控制器中抽取到用户模型中。

### 通用认证

激活链接URL中的激活令牌和邮箱地址分别通过`params[:id]`和`params[:email]`引用，根据密码和记忆令牌的模型，计划使用如下方法验证用户：
```
# 根据用户邮箱地址查找用户对象，判断用户存在且认证成功
user = User.find_by(email: params[:email])
if user && user.authenticated?(:activation, params[:id])
```
以上代码使用`authenticated?`方法验证数据库中保存的账户激活摘要和通过激活链接拿到的激活令牌是否能够匹配。但是现在还无法工作，因为当前它只能处理密码的记忆令牌：
```
def authenticated?(remember_token)
  # 如果没有密码记忆摘要，则返回否
  return false if remember_digest.nil?
  # 查看拿到的记忆令牌与摘要是否匹配
  BCrypt::Password.new(remember_digest).is_password?(remember_token)
end
```
以上的`remember_digest`是用户模型的属性，在模型内部使用`self.remember_digest`引用该属性，属性`activation_digest`也类似。为了在同一方法中对这两个属性通过同一变量引用，这里介绍Ruby的特性之一`metaprogramming`概念，即使用一个程序编写另一个程序。本例中，关键是`send`方法，它可以作为对象实例的内建方法返回属性值：
```
$ rails console
>> a = [1, 2, 3]
# 查看数组对象的内建属性
>> a.length
=> 3
# 使用实例对象的内建方法`send`返回属性值
>> a.send(:length)
=> 3
>> a.send("length")
=> 3
# 使用如上的类似方法返回用户实例的属性值
>> user = User.first
>> user.activation_digest
=> "$2a$10$qR7ZAXyKCFcm8YfL1t31VuVxvc1sgYD/jjI.HEmUIbLHvel38K1Rm"
>> user.send(:activation_digest)
=> "$2a$10$qR7ZAXyKCFcm8YfL1t31VuVxvc1sgYD/jjI.HEmUIbLHvel38K1Rm"
>> user.send("activation_digest")
=> "$2a$10$qR7ZAXyKCFcm8YfL1t31VuVxvc1sgYD/jjI.HEmUIbLHvel38K1Rm"
>> attribute = :activation
=> :activation
>> user.send("#{attribute}_digest")
=> "$2a$10$qR7ZAXyKCFcm8YfL1t31VuVxvc1sgYD/jjI.HEmUIbLHvel38K1Rm"
```

如上，在`user`实例对象上调用`send`方法，加上用变量名生成的属性值，即可用同一个方法处理记忆令牌摘要和激活令牌摘要。据此，更新用户模型：
`app/models/user.rb`
```
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end
```

由于以上更新改变了`authenticated?`方法的调用方式，这里还需要更新使用`authenticated?`的方法，例如会话帮助文件：
`app/helpers/sessions_helper.rb`
```
  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      # 更新以下一行代码，更改硬写入的密码记忆摘要参数为新的编程方式生成
      if user && user.authenticated?(:remember, cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end
```

以及用户模型的测试文件：
`test/models/user_test.rb`
```
  test "authenticated? should return false for a user with nil digest" do
    # 更新这里的一行代码，同样更新记忆令牌参数的生成方式
    assert_not @user.authenticated?(:remember, '')
  end
```

### 激活用`edit`方法

更新用户激活控制器，添加`edit`方法用于激活用户：
`app/controllers/account_activations_controller.rb`
```
    def edit
        # 根据URL中的email参数查找用户账户
        user = User.find_by(email: params[:email])
        # 在用户账户存在，尚未激活，且认证通过的情况下继续
        if user && !user.activated? && user.authenticated?(:activation, params[:id])
          # 更新已激活账户属性为真，更新激活时间戳为当前时间
          user.update_attribute(:activated,    true)
          user.update_attribute(:activated_at, Time.zone.now)
          # 登录当前用户，显示激活成功的闪信，并重定向到用户简介页面
          log_in user
          flash[:success] = "Account activated!"
          redirect_to user
        # 如果用户账户不存在或认证没有通过，则返回错误信息，重定向到网站根页面
        else
          flash[:danger] = "Invalid activation link"
          redirect_to root_url
        end
    end
```
以上代码的逻辑是，根据邮箱地址找到用户，判断用户账户存在且尚未激活，且得到的激活令牌与保存的摘要相匹配，即认证成功。如是，则更新用户的激活状态属性值为真，更新激活时间属性为当前时间，登录用户，发送账户激活成功的闪信，重定向页面到用户简介页面。否则，闪信显示激活链接无效的信息，重定向到网站根页面。

现在，可以复制之前验证激活邮件时创建新用户得到的激活链接到浏览器，即完成新建用户的账户激活：
```
http://localhost:3000/account_activations/sGhyPVRE5m6EDsJX_Z6Lgg/edit?email=user%40example.com
```
以上为我得到的激活链接。如果页面跳转到用户简介页面，并且有账户已激活的闪信通知出现，则说明账户操作已经成功。

现在，程序实际上允许未激活的用户账户登录，各位可以注册一个新用户验证这个漏洞。为修正该漏洞，需要在用户登录操作的会话控制器动作`create`中加入验证用户账户激活的逻辑：
`app/controllers/sessions_controller.rb`
```
  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      # 更新本部分代码为如下，只允许已激活用户登录，否则显示错误提示并重定向到网站根页面
      if user.activated?
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or user
      else
        message  = "Account not activated. "
        message += "Check your email for the activation link."
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end
```
在确认用户账户存在和密码正确后，判断账户是否激活。如是，则登录用户，跳转到用户简介页面。如否，则闪信通知账户未激活并提示查看邮件确认激活链接，跳转到网站根页面。

### 激活功能的集成测试

这里添加对用户激活功能的集成测试：
`test/integration/users_signup_test.rb`
```
  # 添加如下测试配置
  def setup
    ActionMailer::Base.deliveries.clear
  end

  ...
  
  test "valid signup information with account activation" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name:  "Example User",
                                         email: "user@example.com",
                                         password:              "password",
                                         password_confirmation: "password" } }
    end
    # 添加如下测试语句段落
    # 确认发送了一个邮件，且当前用户账户尚未激活
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    # 测试在账户激活前尝试登录，确认登录不成功
    log_in_as(user)
    assert_not is_logged_in?
    # 测试激活令牌无效，但邮箱有效，确认登录不成功
    get edit_account_activation_path("invalid token", email: user.email)
    assert_not is_logged_in?
    # 测试激活令牌有效，但邮箱错误，确认登录不成功
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not is_logged_in?
    # 测试有效的激活令牌和邮箱，确认登录成功
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?

    follow_redirect!
    # 反注释以下两条语句
    assert_template 'users/show'
    assert is_logged_in?
  end
```

以上语句中，如下语句确认只发送了一条邮件：
```
assert_equal 1, ActionMailer::Base.deliveries.size
```
其中，数组`Base.deliveries`为全局变量，因此需要在配置本测试的`setup`中将其重置，以防止因为其他测试中发送过邮件而更改了该全局变量，影响这里的测试结果。之后的`assigns`语句允许用户访问这里创建的实例变量：
```
user = assigns(:user)
```
例如，用户控制器的`create`动作定义了一个`@user`变量，在测试中可以用`assigns(:user)`访问它。注意，`assigns`方法已经在Rails5中停用，这里通过引用`rails-controller-testing`的gem库继续使用。

现在运行测试一次，确认可以通过，代码没有问题。

### 代码的结构优化

以下，作为对代码的优化，将一部分用户操作从用户控制器移出到用户模型中去，将创建`activate`方法来更新用户激活状态属性，创建`send_activation_email`方法来发送激活邮件。

添加用户激活相关方法到用户模型：
`app/models/user.rb`
```
class User < ApplicationRecord
  ...
  # 激活用户账户
  def activate
    # 设置已激活属性为真，更新激活时间戳为当前时间
    update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end

  # 发送激活邮件
  def send_activation_email
    # 立即发送激活邮件
    UserMailer.account_activation(self).deliver_now
  end

  private
    ...
end
```

通过用户模型对象发送邮件：
`app/controllers/users_controller.rb`
```
  def create
    @user = User.new(user_params)
    if @user.save
      # 添加如下代码，使用用户模型中的方法
      @user.send_activation_email
      # UserMailer.account_activation(@user).deliver_now
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render 'new'
    end
  end
```

通过用户模型对象激活账户：
`app/controllers/account_activations_controller.rb`
```
  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      # 添加如下一行代码，使用用户模型中的方法替换原有的两行代码
      user.activate
      # user.update_attribute(:activated,    true)
      # user.update_attribute(:activated_at, Time.zone.now)
      log_in user
      flash[:success] = "Account activated!"
      redirect_to user
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end
```

作为进一步的优化，可以更新用户模型中的`activate`动作，合并两次数据库访问为一次：
`app/models/user.rb`
```
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
    # update_attribute(:activated,    true)
    # update_attribute(:activated_at, Time.zone.now)
  end
```

再进一步优化，从用户列表中隐藏未激活用户账户，更新用户控制器文件：
`app/controllers/users_controller.rb`
```
  def show
    @user = User.find(params[:id])
    # 添加如下代码，访问未激活用户的简介会直接跳转到网站根页面
    redirect_to root_url and return unless @user.activated?
  end

  def index
    # 更新如下代码，在用户列表中只显示已激活的用户账户
    @users = User.where(activated: true).paginate(page: params[:page])
    # @users = User.paginate(page: params[:page])
  end
```

## 生产环境的邮件

为模拟在生产环境中真正的发送邮件，这里使用Heroku的`SendGrid`添加件，配置过程如下：
```
$ heroku addons:create sendgrid:starter -a <your_app_name>
```
如果提示需要确认账户，则导航到如下链接输入信用卡信息：
`https://heroku.com/verify`
`https://dashboard.heroku.com/account/billing`
之后再次运行安装添加件的命令，确认得到如下关键结果：
```
Created sendgrid-adjacent-26146 as SENDGRID_PASSWORD, SENDGRID_USERNAME
```
作为对安装结果的确认，可以运行如下命令查看SendGrid的用户名和密码：
```
$ heroku config:get SENDGRID_USERNAME
$ heroku config:get SENDGRID_PASSWORD
```
注意，这里查看用户名和密码只是为确认安装成功，之后的操作不需要直接输入该凭据。

更新生产环境配置文件：
`config/environments/production.rb`
```
Rails.application.configure do
  ...
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  host = '<your heroku app>.herokuapp.com'
  config.action_mailer.default_url_options = { host: host }
  ActionMailer::Base.smtp_settings = {
    :address        => 'smtp.sendgrid.net',
    :port           => '587',
    :authentication => :plain,
    # 以下两行代码中的用户名和密码不是占位符，ENV表明了他们是环境变量
    :user_name      => ENV['SENDGRID_USERNAME'],
    :password       => ENV['SENDGRID_PASSWORD'],
    :domain         => 'heroku.com',
    :enable_starttls_auto => true
  }
  ...
end
```

## 收尾

按照惯例，更新在线代码文档库（GitHub）并部署到生成（Heroku）：
```
$ rails test
$ git add -A
$ git commit -m "Add account activation"
$ git checkout master
$ git merge account-activation
$ rails test
$ git push
$ git push heroku
$ heroku run rails db:migrate
```

这里，如果在`git push heroku`部分提示找不到应用，可以用：
```
$ git push heroku -a <your_heroku_app_name>
```

或者绑定Heroku应用到`heroku`关键词，一劳永逸的解决这个问题：
```
$ heroku git:remote -a <your_heroku_app_name>
```

以上`<your_heroku_app_name>`是各位的Heroku应用名称，可以使用各位自己的账户登录Heroku查看。

### 测试生产环境

部署生成后再次通过部署的网站进行用户注册和激活测试，使用有效的邮箱，应该可以收到激活邮件，点击激活连接后跳转到用户简介页面，可以得到账户激活成功提示，祝各位好运。

## 第十二章 重置密码

重置密码涉及修改一个视图和两个表单，处理邮箱和新密码的提交。需要在登录页面添加一个`forgot password`链接，该链接指向一个邮箱地址输入表单，密码重置链接将会通过邮件发送到该邮件地址。还要为密码重置添加新的资源和数据模型，配合`mailer`操作。大致的步骤如下：
1. 当用户请求密码重置，通过邮箱地址找到目标用户
2. 如果邮箱地址可以从数据库中找到，生成重置令牌和相应的摘要
3. 保存重置摘要到数据库，发送包含重置令牌和用户邮箱地址的链接给用户
4. 当用户点击该链接，通过邮箱找到用户，通过比较重置摘要认证用户
5. 如果认证通过，跳转到密码重置页面以便用户更新密码

### 密码重置资源

虽然与`Active Record`模型没有直接关系，我们仍将密码重置作为资源建模，包括重置令牌在内的相关数据将包含在用户模型中。在Rails程序中，用户与资源的交互方式总是标准REST类型的URL，这里需要`new`，`create`，`edit`和`update`四个REST类型的URL。

为本节创建独立的代码分支，为密码重置资源创建控制器，同时创建`new`和`edit`动作：
```
$ git checkout -b password-reset
$ rails generate controller PasswordResets new edit --no-test-framework
```
注意以上语句中使用`--no-test-framework`参数指明生成的控制器不包含测试模块，因为我们不需要对该控制器做测试，相关的测试将通过更新前一章节的集成测试完成。下面更新路径设置文件：
`config/routes.rb`
```
Rails.application.routes.draw do
  ...
  # 追加如下一条路由设置
  resources :password_resets,     only: [:new, :create, :edit, :update]
end
```
以上路由设置产生的URL详情如下：
HTTP request | URL | Action | Named route
GET | /password_resets/new | new | new_password_reset_path
POST | /password_resets | create | password_resets_path
GET | http://ex.co/password_resets/<token>/edit | edit | edit_password_reset_url(token)
PATCH | /password_resets/<token> | update | password_reset_path(token)

更新登录页面视图，添加一个重置密码的链接：
`app/views/sessions/new.html.erb`
```
<div class="row">
  <div class="col-md-6 col-md-offset-3">
    <%= form_for(:session, url: login_path) do |f| %>
      ...
      <%= f.label :password %>
      # 添加如下一条语句
      <%= link_to "(forgot password)", new_password_reset_path %>
      <%= f.password_field :password, class: 'form-control' %>
      ...
    <% end %>
    <p>New user? <%= link_to "Sign up now!", signup_path %></p>
  </div>
</div>
```

#### 密码重置`new`动作

与验证密码和用户激活令牌类似，基于安全上的考量，密码重置请求的验证也涉及一对令牌和摘要。否则，恶意用户可以通过访问数据库获取明文保存的密码重置令牌，进而重置用户密码和控制用户账户。为了给密码重置令牌增加过期时间设置，额外需要增加一个密码重置请求的时间戳。用户模型需要添加如下两个属性：
* reset_digest: string
* reset_sent_at: datetime

为增加以上两个属性，运行如下命令：
```
$ rails generate migration add_reset_to_users reset_digest:string \
> reset_sent_at:datetime
$ rails db:migrate
```
注意，以上命令中第二行的`>`是命令行跨行继续的标志，由终端自动加入不需要手动输入。如果拷贝命令到终端，留意`>`标志没有重复出现，否则运行不会报错但第二个属性`reset_sent_at`不会添加成功。

更新密码重置的`new`视图文件：
`app/views/password_resets/new.html.erb`
```
<% provide(:title, "Forgot password") %>
<h1>Forgot password</h1>
<div class="row">
  <div class="col-md-6 col-md-offset-3">
    <%= form_for(:password_reset, url: password_resets_path) do |f| %>
      <%= f.label :email %>
      <%= f.email_field :email, class: 'form-control' %>
      <%= f.submit "Submit", class: "btn btn-primary" %>
    <% end %>
  </div>
</div>
```

#### 密码重置`create`动作

在`new`页面中提交邮箱地址后，需要根据提交的邮箱地址找到用户，使用密码重置令牌和时间戳更新用户属性，然后跳转到网站根页面，显示一条通知闪信。在提交信息无效的情况下，重新生成密码重置的`new`页面，更新密码重置控制器：
`app/controllers/password_resets_controller.rb`
```
  # 添加如下动作定义
  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = "Email sent with password reset instructions"
      redirect_to root_url
    else
      flash.now[:danger] = "Email address not found"
      render 'new'
    end
  end
```

更新用户模型定义文件：
`app/models/user.rb`
```
class User < ApplicationRecord
  # 更新如下一条代码
  attr_accessor :remember_token, :activation_token, :reset_token
  ...

  # 设定密码重置属性
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  # 发送密码重置邮件
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  private
    ...
end
```

### 密码重置邮件

由于前一章节已经生成了部分文件，这里更新即可：
`app/mailers/user_mailer.rb`
```
class UserMailer < ApplicationMailer
  ...
  # 更新如下方法
  def password_reset(user)
    @user = user
    mail to: user.email, subject: "Password reset"
  end
end
```

更新密码重置的纯文本邮件模版：
`app/views/user_mailer/password_reset.text.erb`
```
To reset your password click the link below:
<%= edit_password_reset_url(@user.reset_token, email: @user.email) %>
This link will expire in two hours.
If you did not request your password to be reset, please ignore this email and
your password will stay as it is.
```

更新密码重置的HTML邮件模版：
`app/views/user_mailer/password_reset.html.erb`
```
<h1>Password reset</h1>
<p>To reset your password click the link below:</p>

<%= link_to "Reset password", edit_password_reset_url(@user.reset_token,
                                                      email: @user.email) %>
<p>This link will expire in two hours.</p>

<p>If you did not request your password to be reset, please ignore this email and
your password will stay as it is.</p>
```

更新邮件预览定义文件：
`test/mailers/previews/user_mailer_preview.rb`
```
  # 更新密码重置的邮件预览定义如下
  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/password_reset
  def password_reset
    user = User.first
    user.reset_token = User.new_token
    UserMailer.password_reset(user)
  end
```

现在可以到如下地址确认邮件模版：
```
http://localhost:3000/rails/mailers/user_mailer/password_reset
```

在密码重置页面输入有效的邮箱，从服务器日志和Rails操作台查看用户密码重置的请求、响应和相关属性的生成情况。最后添加一个对密码重置的测试：
`test/mailers/user_mailer_test.rb`
```
  test "password_reset" do
    user = users(:michael)
    user.reset_token = User.new_token
    mail = UserMailer.password_reset(user)
    assert_equal "Password reset", mail.subject
    assert_equal [user.email], mail.to
    assert_equal ["noreply@example.com"], mail.from
    assert_match user.reset_token,        mail.body.encoded
    assert_match CGI.escape(user.email),  mail.body.encoded
  end
```
现在运行测试，确认测试可以顺利通过。

### 重置密码

这一部分将写密码重置控制器的`edit`动作用于执行密码重置操作，并准备集成测试。

#### `edit`动作

密码重置邮件将包含如下链接：
```
<server_url>/password_resets/<reset_digest>/edit?email=<user_email>
```
重置密码的表单与更新用户简介的表单类似，只是内容更简单，只包含输入和确认新密码的字段。因为需要用户邮箱来查找用户账户，在`edit`和`update`动作中都会用到。用户邮箱会在`edit`动作中有效，因为包含在密码重置URL中，直到提交表单。解决方案是使用一个隐藏的字段，将用户邮箱放到表单中但不显示在页面上，并随其他表单信息一同提交。

更新密码重置的编辑视图：
`app/views/password_resets/edit.html.erb`
```
<% provide(:title, 'Reset password') %>
<h1>Reset password</h1>
<div class="row">
  <div class="col-md-6 col-md-offset-3">
    <%= form_for(@user, url: password_reset_path(params[:id])) do |f| %>
      <%= render 'shared/error_messages' %>
      # 关键是添加如下一条语句
      <%= hidden_field_tag :email, @user.email %>
      <%= f.label :password %>
      <%= f.password_field :password, class: 'form-control' %>
      <%= f.label :password_confirmation, "Confirmation" %>
      <%= f.password_field :password_confirmation, class: 'form-control' %>
      <%= f.submit "Update password", class: "btn btn-primary" %>
    <% end %>
  </div>
</div>
```
以上的隐藏字端使用的是`hidden_field_tag :email, @user.email`，而不是`f.hidden_field :email, @user.email`，因为前者允许重置链接使用`params[:email]`引用用户邮箱，后者需要`params[:user][:email]`。

为了启用表单，需要在密码重置控制器的`edit`动作中定义`@user`变量，并确保在`edit`和`update`动作之前完成。就像用户激活，需要根据`params[:email]`中的邮箱信息找到用户账户，并确认用户有效，即存在、已经激活且可根据`params[:id]`中的重置令牌完成认证，为此更新密码重置控制器：
`app/controllers/password_resets_controller.rb`
```
class PasswordResetsController < ApplicationController
  # 在控制器头部添加如下两个过滤条件，强制在动作前找到并认证用户
  before_action :get_user,   only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  ...
  def edit
  end

  # 添加如下私有方法代码块
  private
    # 查找用户
    def get_user
      @user = User.find_by(email: params[:email])
    end
    # 验证用户
    def valid_user
      unless (@user && @user.activated? &&
              @user.authenticated?(:reset, params[:id]))
        redirect_to root_url
      end
    end
end
```

#### `update`动作

账户激活的`edit`动作更新用户激活属性，从`未激活`到`已激活`。密码重置的`edit`动作提交一个表单到`update`动作，并需要做如下考虑：
1. 密码重置请求过期
2. 由于不符合密码复杂度要求，密码重置更新失败
3. 空密码和空密码确认造成的更新成功假象
4. 成功的更新

基于以上考量，更新密码重置控制器如下：
`app/controllers/password_resets_controller.rb`
```
class PasswordResetsController < ApplicationController
  before_action :get_user,         only: [:edit, :update]
  before_action :valid_user,       only: [:edit, :update]
  # 添加如下动作过滤器，用于处理密码重置请求过期的情况
  before_action :check_expiration, only: [:edit, :update]

  ...

  def update
    # 判断密码重置是否为空
    if params[:user][:password].empty?
      @user.errors.add(:password, "can't be empty")
      render 'edit'
    # 更新用户属性成功
    elsif @user.update_attributes(user_params)
      log_in @user
      flash[:success] = "Password has been reset."
      redirect_to @user
    # 其他更新失败的情况，如密码不符合复杂度要求
    else
      render 'edit'
    end
  end

  private
    # 强制只接收密码和密码确认两个参数
    def user_params
      params.require(:user).permit(:password, :password_confirmation)
    end
    ...

    # 检查密码重置令牌是否过期
    def check_expiration
      if @user.password_reset_expired?
        flash[:danger] = "Password reset has expired."
        redirect_to new_password_reset_url
      end
    end
end
```
注意：
1. 以上私有方法`check_expiration`调用的用户实例`password_reset_expired?`方法需要在用户模型中定义。
2. 目前的用户模型允许空密码，参考以下密码验证语句，这里需要对重置密码为空的操作做出特别处理：
```
validates :password, presence: true, length: { minimum: 8 }, allow_nil: true
```

更新用户模型，添加`password_reset_expired?`方法定义：
`app/models/user.rb`
```
class User < ApplicationRecord
  ...
  # 若密码重置请求提交超过两小时则返回真
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  private
    ...
end
```

现在可以在密码重置页面验证之前定义的四种场景。

#### 密码重置测试

生成测试文件模版：
```
$ rails generate integration_test password_resets
```

具体测试过程与账户激活类似，流程如下：
1. 访问`forgot password`链接
2. 先后提交无效和有效的用户邮箱地址
3. 对有效邮箱地址生成密码重置令牌并发送重置邮件
4. 通过邮件访问重置链接，先后提交无效和有效信息
5. 验证密码重置页面可以正确处理无效和有效信息

根据以上流程更新密码重置的集成测试：
`test/integration/password_resets_test.rb`
```
require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test "password resets" do
    # 导航到密码重置页面，确认使用了正确视图模版
    get new_password_reset_path
    assert_template 'password_resets/new'
    # 输入无效邮箱地址，确认闪信内容不为空，跳转回密码重置页面
    post password_resets_path, params: { password_reset: { email: "" } }
    assert_not flash.empty?
    assert_template 'password_resets/new'
    # 输入有效的邮箱地址，确认重置摘要有更新，发送了一封邮件，闪信不为空，重定向到根页面
    post password_resets_path,
         params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # 将当前用户读入变量
    user = assigns(:user)
    # 重置链接中提交无效邮箱信息，重定向到根页面
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    # 重置链接中邮箱关联的用户账户未激活，重定向到根页面
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    # 重置链接中的邮箱和相关用户有效，但激活令牌无效，重定向到根页面
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    # 重置链接中邮箱和激活令牌都有效，确认抵达密码重制`edit`视图，页面中有隐藏邮箱字段
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    # 测试在密码重置页面提交不匹配的密码和密码确认，确认有错误信息
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password:              "foobaz",
                            password_confirmation: "barquux" } }
    assert_select 'div#error_explanation'
    # 测试更新为空密码，确认有错误信息
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password:              "",
                            password_confirmation: "" } }
    assert_select 'div#error_explanation'
    # 测试更新密码有效，确认用户自动登录，闪信不为空，页面跳转到和用户简介
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password:              "foobaz",
                            password_confirmation: "foobaz" } }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
  end
end
```
运行测试，验证没有错误。

#### 一点优化

更新用户模型的重置摘要生成方法，将两次数据库访问合并为一次：
`app/models/user.rb`
```
  def create_reset_digest
    self.reset_token = User.new_token
    # 以下为合并后的方法
    update_columns(reset_digest:  User.digest(reset_token), reset_sent_at: Time.zone.now)
    # 以下为合并之前的方法
    # update_attribute(:reset_digest,  User.digest(reset_token))
    # update_attribute(:reset_sent_at, Time.zone.now)
  end
```

更新密码重置集成测试，增加对过期密码重置请求的测试：
`test/integration/password_resets_test.rb`
```
require 'test_helper'
class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end
  ...
  test "expired token" do
    get new_password_reset_path
    post password_resets_path,
         params: { password_reset: { email: @user.email } }

    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(@user.reset_token),
          params: { email: @user.email,
                    user: { password:              "foobar",
                            password_confirmation: "foobar" } }
    assert_response :redirect
    follow_redirect!
    assert_match /expired/i, response.body
  end
end
```
以上验证密码重置请求过期处理结果，在重定向后的页面中寻找`expired`关键字。

作为一个安全漏洞，保存在数据库中的密码重置摘要应该在密码成功修改后清空，否则恶意用户可以在两小时过期时间内再次使用同一密码重置链接访问密码重置页面，重置密码并控制相应的用户账户。为此，更新密码重置控制器：
`app/controllers/password_resets_controller.rb`
```
class PasswordResetsController < ApplicationController
  ...
  def update
    if params[:user][:password].empty?
      @user.errors.add(:password, "can't be empty")
      render 'edit'
    elsif @user.update_attributes(user_params)
      log_in @user
      # 增加如下一行代码
      @user.update_attribute(:reset_digest, nil)
      flash[:success] = "Password has been reset."
      redirect_to @user
    else
      render 'edit'
    end
  end
  ...
end
```
为测试账户密码重置后清除密码重置摘要，更新密码重置的集成测试：
``
```
  test "password resets" do
    ...
    assert_redirected_to user
    # 增加如下一条语句，验证成功重置密码后摘要已经从用户属性中清除
    assert_nil user.reload.reset_digest
  end
```

运行测试，验证一切正常。也可以修改程序源码或测试代码进行反向测试。

### 生产邮件和收尾

参考前一个章节的生产邮件章节，如果配置了SendGrid这里就不需要再操作。进入收尾：
```
$ rails test
$ git add -A
$ git commit -m "Add password reset"
$ git checkout master
$ git merge password-reset
$ rails test
$ git push
$ git push heroku
$ heroku run rails db:migrate
```

打开Heroku的APP链接，验证已有用户的密码重置功能，祝你好运。

# 第十三章 用户微博

先处理一个小问题，从代码库克隆之前留下的程序到本地，尝试运行Rails服务器也会遇到关于数据库迁移的错误。解决办法并不复杂，重置数据库并重新生成测试数据即可：
```
$ rails db:migrate:reset
$ rails db:seed
```

到目前为止，程序涉及了四个资源，分别是用户、会话、账户激活和密码重置，只有用户资源是基于`Active Record`模型，在数据库中也有相应的表格对应。本节创建另外一个类似资源，叫做用户微博，即与某个用户有关的短信息。

首先创建微博数据模型，接着使用`has_many`和`belongs_to`方法关联到用户模型，最后创建必要的表单和片段来编辑和显示微博。下一节，作为本系列教程的最后一部分，将添加类似Twitter的关注功能，接收来自关注对象用户的微博更新。

## 微博模型

微博数据模型描述微博的基本特性，包含数据验证功能，并关联到用户模型。另外，也会添加相关测试，带有默认的排序功能，和自动销毁功能，以便在微博所有者用户账户删除同时删除所有所属的相关微博。创建本节代码分支：
```
$ git checkout -b user-microposts
```

### 基本模型

微博数据模型以`microposts`为对象名称，包含以下属性和数据类型定义：
```
id         / integer  # 每条微博的唯一标识符
content    / text     # 微博内容
user_id    / integer  # 微博创建者用户账户ID
create_at  / datetime # 微博创建时间戳
updated_at / datetime # 微博修改时间戳 
```

对于微博属性`content`的数据类型定义用`text`而不用`string`基于以下考量。
* 更好的表达了微博作为一个文本片段的自然属性，而不仅仅是一个字符串。
* 视图文件中也会用`text area`即文本区域，而不是`text`字端承载。
* 为应用提供更大的弹性，在日后为国际化等需求扩展微博容量时留有余地。
* PostgreSQL推荐使用可变或无限容量的数据类型以保证更高运行效率*。
* 如上，目前限制容量设为140个字符，即便可以用字符串类型承载也不用。

使用Rails自带功能自动生成微博数据模型，注意指定的属性值和数据类型：
```
$ rails generate model Micropost content:text user:references
```

以上命令生成微博模型如下，带有`belongs_to :user`，因为生成命令中`user:references`的定义：
`app/models/micropost.rb`
```
class Micropost < ApplicationRecord
  belongs_to :user
end
```

相应的数据库迁移文件和更新如下：
`db/migrate/[timestamp]_create_microposts.rb`
```
class CreateMicroposts < ActiveRecord::Migration[5.0]
  def change
    # 在数据库中创建微博表格
    create_table :microposts do |t|
      # 使用微博属性值填充表格列，并建立外键关系
      t.text :content
      t.references :user, foreign_key: true
      # 添加创建时间和更改时间两个属性和表格列
      t.timestamps
    end
    # 以下语句需要更新添加，使用用户ID和创建时间为微博记录创建索引
    add_index :microposts, [:user_id, :created_at]
  end
end
```
以上语句中的外键设置也同样由生成模型语句中的`user:references`部分自动添加。以上索引相关语句需要自行添加，以便按照用户和逆序创建时间列印微博。

先使用迁移命令更新数据库，再在Rails控制台中测试新建的微博数据模型：
```
# 更新数据库
$ rails db:migrate
$ rails console
# 查看新的微博对象所带有的属性
> Micropost.new
# 创建一个微博对象，同时通过返回的信息确认各属性值
> post = Micropost.new(content:"a testing message", user_id:1)
# 查看新建微博对象的用户属性和用户名子属性
> post.user
> post.user.name
# 保存新建微博对象到数据库后，再次确认各属性值，特别是时间戳的更新
> post.save
> post
```

### 有效验证

为验证微博对象有效，这里添加对所有者用户字端的存在和微博内容的存在与长度做验证，首先写出测试情景：
`test/models/micropost_test.rb`
```
require 'test_helper'
class MicropostTest < ActiveSupport::TestCase
  # 初始化一个用户和一个微博用于测试
  def setup
    @user = users(:michael)
    @micropost = Micropost.new(content: "Lorem ipsum", user_id: @user.id)
  end
  # 验证微博在正确创建时有效
  test "should be valid" do
    assert @micropost.valid?
  end
  # 测试用户ID不存在时微博无效
  test "user id should be present" do
    @micropost.user_id = nil
    assert_not @micropost.valid?
  end
  # 测试微博内容为空时微博无效
  test "content should be present" do
    @micropost.content = "   "
    assert_not @micropost.valid?
  end
  # 测试微博内容长度超过140字符时无效
  test "content should be at most 140 characters" do
    @micropost.content = "a" * 141
    assert_not @micropost.valid?
  end
end
```
这里，初始化测试用微博实例时使用的是微博模型本身，实际上更理想的方式是使用`Active Record`的`关联`功能。

对应测试场景，更新微博模型定义如下：
`app/models/micropost.rb`
```
class Micropost < ApplicationRecord
  belongs_to :user
  # 验证用户ID存在
  validates :user_id, presence: true
  # 验证微博内容存在，内容长度最大为140
  validates :content, presence: true, length: { maximum: 140 }
end
```

运行测试，验证可以通过。

### 用户与微博关联

用户和微博的模型之间存在一对多的逻辑关系，即每个用户可以有多个微博，但每个微博只属于一个用户，这样的关系叫做关联，可以通过模型的定义实现。在设置了正确的关联关系后，系统会自动生成如下方法：
```
方法名称 / 作用
micropost.user                / 返回与微博相关联的用户对象
user.microposts               / 返回该用户创建的一系列微博
user.microposts.create(arg)   / 创建一个与指定用户关联的微博
user.microposts.create!(arg)  / 同上，失败时创建意外事件
user.microposts.build(arg)    / 返回一个与指定用户关联的微博
user.microposts.find_by(id:n) / 找到属于指定用户且ID为n的微博
```

更新用户和微博模型的操作，在之前的微博模型创建中已经完成了一半，即微博模型中的`belongs_to :user`语句，指定了多对一的从微博到用户的关联。这里手动更新用户模型，建立一对多的用户到微博关联：
`app/models/user.rb`
```
class User < ApplicationRecord
  has_many :microposts
  ...
end
```

在以上的关联设置完成后，可以更新微博的模型测试：
`test/models/micropost_test.rb`
```
require 'test_helper'
class MicropostTest < ActiveSupport::TestCase
  def setup
    @user = users(:michael)
    # 更新以下语句，使用更理想的方式创建测试用微博对象
    @micropost = @user.microposts.build(content: "Lorem ipsum")
  end
  ...
end
```

在Rails控制台测试到目前为止的模型关联设置：
```
$ rails console
# 使用数据库中的第一个用户创建用户对象
> user = User.find(1)
# 使用该用户关联微博的创建方法生成一个微博对象
> post = user.microposts.create(content: "Lorem ipsum")
# 使用该用户关联微博的查找方法查找到微博
> user.microposts.find(micropost.id)
# 确认用户对象和微博对象关联的用户是同一个
> user == micropost.user
=> true
# 确认用户关联微博的第一个与该微博对象为同一个
> user.microposts.first == micropost
```
以上测试验证了用户和微博模型之间的关联方法有效。

### 关联优化

这一部分处理用户微博的列印顺序，并配置微博依赖于用户以便在用户账户删除时自动删除该账户的所属微博。

返回某个用户全部微博的方法`user.microposts`方法不保证返回微博的顺序，但根据其他博客应用的惯例，一般会把最新的微博放在最前列，以便访客可以看到最新的更新。依旧按照TDD流程，先写出测试模块，准备测试用数据：
`test/fixtures/microposts.yml`
```
orange:
  content: "I just ate an orange!"
  created_at: <%= 10.minutes.ago %>

tau_manifesto:
  content: "Check out the @tauday site by @mhartl: http://tauday.com"
  created_at: <%= 3.years.ago %>

cat_video:
  content: "Sad cats are sad: http://youtu.be/PKffm2uI4dk"
  created_at: <%= 2.hours.ago %>

most_recent:
  content: "Writing a short test"
  created_at: <%= Time.zone.now %>
```

以上测试数据准备了四个发布于不同时间的微博对象。接着，更新微博模型测试定义：
`test/models/micropost_test.rb`
```
require 'test_helper'
class MicropostTest < ActiveSupport::TestCase
  ...
  test "order should be most recent first" do
    assert_equal microposts(:most_recent), Micropost.first
  end
end
```

现在运行测试会得到失败结果哦，因为微博模型中没有定义返回微博的顺序，为此更新微博模型：
`app/models/micropost.rb`
```
class Micropost < ApplicationRecord
  belongs_to :user
  # 添加以下默认范围定义，按创建时间的逆序排列
  default_scope -> { order(created_at: :desc) }
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
end
```

系统默认的时间表示方法是连续增长的数字，值越大表示越靠近当前时间。而默认的排序为递增，也就是越靠近当前的时间越排序在后面或下方。我们要方便的查看最新的微博，也就是希望越靠近当前的时间越排序在前面或上方，故加入逆序参数`desc`。

现在运行测试，确认可以通过。下一步，通过在用户模型中添加与微博的依赖关系，让系统在删除用户的同时删除其拥有的所有微博。更新用户模型：
`app/models/user.rb`
```
class User < ApplicationRecord
  # 更新以下一条语句，为删除操作建立依赖关系
  has_many :microposts, dependent: :destroy
  ...
end
```

为验证用户模型的更新有效，更新用户模型测试定义：
`test/models/user_test.rb`
```
require 'test_helper'
class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(name: "Example User", email: "user@example.com",
                     password: "foobar", password_confirmation: "foobar")
  end
  ...
  # 保存测试用户，创建一条微博，删除用户并确认微博数量也减少一个
  test "associated microposts should be destroyed" do
    @user.save
    @user.microposts.create!(content: "Lorem ipsum")
    assert_difference 'Micropost.count', -1 do
      @user.destroy
    end
  end
end
```

运行测试，确认可以通过。

## 列印微博

为了简化程序的设计，微博将列印在用户简介页面`show.html.erb`，同时显示该用户总共拥有的微博数量。

### 列印微博

列印微博使用的方法与列印用户类似。先重置数据库，创建微博的控制器和视图文件：
```
$ rails db:migrate:reset
$ rails db:seed
$ rails generate controller Microposts
```

这里先创建用于显示每条微博的代码片段：
`app/views/microposts/_micropost.html.erb`
```
<li id="micropost-<%= micropost.id %>">
  <%= link_to gravatar_for(micropost.user, size: 50), micropost.user %>
  <span class="user"><%= link_to micropost.user.name, micropost.user %></span>
  <span class="content"><%= micropost.content %></span>
  <span class="timestamp">
    Posted <%= time_ago_in_words(micropost.created_at) %> ago.
  </span>
</li>
```
注意以上代码中使用了`time_ago_in_words`的帮助方法，会自动根据代入的参数计算到当前时间的偏移，并以友好的可读方式显示。每个列表对象带有一个为定义CSS格式而准备的唯一ID，以便在未来为某个单独微博记录添加格式定义提供方便。

为了在用户的简介视图中显示微博对象，更新用户控制器以引入用户拥有的微博数组变量：
`app/controllers/users_controller.rb`
```
class UsersController < ApplicationController
  ...
  def show
    @user = User.find(params[:id])
    # 添加以下一行代码，引入用户所拥有的微博数组变量
    @microposts = @user.microposts.paginate(page: params[:page])
    redirect_to root_url and return unless @user.activated?
  end
  ...
end
```

更新用户简介页面：
`app/views/users/show.html.erb`
```
<% provide(:title, @user.name) %>
<div class="row">
  <aside class="col-md-4">
    <section class="user_info">
      <h1>
        <%= gravatar_for @user %>
        <%= @user.name %>
      </h1>
    </section>
  </aside>
  # 更新如下代码段
  <div class="col-md-8">
    <% if @user.microposts.any? %>
      <h3>Microposts (<%= @user.microposts.count %>)</h3>
      <ol class="microposts">
        <%= render @microposts %>
      </ol>
      <%= will_paginate @microposts %>
    <% end %>
  </div>
</div>
```

以上用户视图更新的代码片段比较有趣，这里逐一解释如下：
* <% if @user.microposts.any? %> 检查当前用户是否拥有微博，如果没有则不显示下面的部分
* <%= @user.microposts.count %> 不会显示当前页面的微博数量，而是该用户的微博总数
* <ol class="microposts"> 创建的是带顺序的列表，因为我们希望列印的微博带有顺序
* <%= render @microposts %> 调用之前创建的用于显示每条微博的代码片段，以逐条列印微博
* <%= will_paginate @microposts %> 因为在用户视图中分页微博，需要指明微博数组对象

### 微博样本

为测试微博列印效果，生成样本微博的方式与样本用户类似，更新数据库种子文件定义如下：
`db/seeds.rb`
```
...
users = User.order(:created_at).take(6)
50.times do
  content = Faker::Lorem.sentence(5)
  users.each { |user| user.microposts.create!(content: content) }
end
```

重置数据库并再次生成种子：
```
$ rails db:migrate:reset
$ rails db:seed
```

此时重起Rails服务器并登录，可以看到列印微博格式有待改善，更新自定义格式文件：
`app/assets/stylesheets/custom.scss`
```
...
/* 微博自定义格式 */

.microposts {
  list-style: none;
  padding: 0;
  li {
    padding: 10px 0;
    border-top: 1px solid #e8e8e8;
  }
  .user {
    margin-top: 5em;
    padding-top: 0;
  }
  .content {
    display: block;
    margin-left: 60px;
    img {
      display: block;
      padding: 5px 0;
    }
  }
  .timestamp {
    color: $gray-light;
    display: block;
    margin-left: 60px;
  }
  .gravatar {
    float: left;
    margin-right: 10px;
    margin-top: 5px;
  }
}

aside {
  textarea {
    height: 100px;
    margin-bottom: 5px;
  }
}

span.picture {
  margin-top: 10px;
  input {
    border: 0;
  }
}
```
保存以上更改，刷新用户微博列印视图，确认格式已经得到改善。

拾遗如下：
```
$ rails console
# 转换成数组并提取
> (1..10).to_a.take(6)
=> [1, 2, 3, 4, 5, 6]
# 不做转换直接提取也会默认转换
> (1..10).take(6)
=> [1, 2, 3, 4, 5, 6]
# 得到不同的虚拟的各种样本
> Faker::University.name
=> "The Hilll"
> Faker::PhoneNumber.phone_number
=> "353-107-3379 x4100"
> Faker::PhoneNumber.cell_phone
=> "(557) 733-3715"
> Faker::Hipster.sentence
=> "Helvetica chambray small batch authentic viral."
> Faker::ChuckNorris.fact
=> "Chuck Norris can instantiate an abstract class."
```
https://github.com/faker-ruby/faker/blob/master/doc/default/university.md
https://github.com/faker-ruby/faker/blob/master/doc/default/phone_number.md
https://github.com/faker-ruby/faker/blob/master/doc/default/hipster.md
https://github.com/faker-ruby/faker/blob/master/doc/default/chuck_norris.md

### 简介页面测试

在更新了简介页面的设计后，这里建立相关集成测试如下：
```
$ rails generate integration_test users_profile
```

更新微博的测试用样本信息：
`test/fixtures/microposts.yml`
```
orange:
  content: "I just ate an orange!"
  created_at: <%= 10.minutes.ago %>
  # 添加以下用户信息以便Rails自动建立与用户样本的关联
  user: michael

tau_manifesto:
  content: "Check out the @tauday site by @mhartl: http://tauday.com"
  created_at: <%= 3.years.ago %>
  # 如上
  user: michael

cat_video:
  content: "Sad cats are sad: http://youtu.be/PKffm2uI4dk"
  created_at: <%= 2.hours.ago %>
  # 如上
  user: michael

most_recent:
  content: "Writing a short test"
  created_at: <%= Time.zone.now %>
  # 如上
  user: michael

# 使用嵌入式Ruby命令自动生成大量测试用微博样本
<% 30.times do |n| %>
micropost_<%= n %>:
  content: <%= Faker::Lorem.sentence(5) %>
  created_at: <%= 42.days.ago %>
  # 如上
  user: michael
<% end %>
```

更新用户简介的集成测试，检查页面标题和用户名、头像、微博数量和分页：
`test/integration/users_profile_test.rb`
```
require 'test_helper'
class UsersProfileTest < ActionDispatch::IntegrationTest
  # 导入如下模块，以便使用full_title帮助方法
  include ApplicationHelper
  def setup
    @user = users(:michael)
  end
  test "profile display" do
    # 导航到用户简介页面
    get user_path(@user)
    # 确认页面使用的模版正确
    assert_template 'users/show'
    # 确认页面标题为用户名
    assert_select 'title', full_title(@user.name)
    # 确认页面中有H1对象，内容为用户名
    assert_select 'h1', text: @user.name
    # 确认在H1对象中哟偶一个img对象，CSS类定义为gravatar
    assert_select 'h1>img.gravatar'
    # 将微博数量值转换为字符，确认在页面显示源码中存在
    assert_match @user.microposts.count.to_s, response.body
    # 确认页面中存在且只存在一个div的分页对象
    assert_select 'div.pagination'
    # 确认分页页面1中的每个微博的内容都在页面显示源码中可以找到
    @user.microposts.paginate(page: 1).each do |micropost|
      assert_match micropost.content, response.body
    end
  end
end
```

现在运行测试，确认可以通过。

## 创建和删除微博

微博资源的接口在用户简介和网站根页面，因此我们不需要在微博的控制器中添加`new`和`edit`动作，只需要`create`和`destroy`动作即可。

更新路由设置：
`config/routes.rb`
```
Rails.application.routes.draw do
  ...
  # 只需要在其他路由设置的最后添加如下一条语句
  resources :microposts, only: [:create, :destroy]
end
```

以上路由设置新增的URL路径如下：
```
HTTP request / URL          / Action  / Named route
POST         / microposts   / create  / microposts_path
DELETE       / microposts/1 / destroy / micropost_path(micropost)
```

相比由Rails命令自动生成的配置而言，以上手动设置虽然更简单但却也需要对Rails技术架构更深入的理解。

### 访问控制

因为只有微博的所有者才可以使用`create`和`destroy`动作，微博控制器中需要为这两个方法设置用户登录前提条件。对没有登录的用户，尝试使用以上两个方法的结果应该是微博总数不变，页面跳转到登录页，因此先更新微博控制器测试：
`test/controllers/microposts_controller_test.rb`
```
require 'test_helper'
class MicropostsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @micropost = microposts(:orange)
  end

  test "should redirect create when not logged in" do
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: { content: "Lorem ipsum" } }
    end
    assert_redirected_to login_url
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference 'Micropost.count' do
      delete micropost_path(@micropost)
    end
    assert_redirected_to login_url
  end
end
```

为通过以上测试，需要先将确认用户已登录的`logged_in_user`方法从用户控制器中迁移到应用控制器中，以便微博控制器也可以设置该方法为前提条件。应用控制器会被所有其他控制器继承，其中的方法也可用于其他控制器：
`app/controllers/application_controller.rb`
```
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  private

    # Confirms a logged-in user.
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please log in."
        redirect_to login_url
      end
    end
end
```

现更新微博控制器，增加对创建和销毁微博方法的登录限制条件：
`app/controllers/microposts_controller.rb`
```
class MicropostsController < ApplicationController
  # 添加前提条件，只允许已登录用户访问创建和删除微博的方法
  before_action :logged_in_user, only: [:create, :destroy]

  def create
  end

  def destroy
  end
end
```

运行测试，确认到目前为止的代码没有问题。

### 创建微博

之前在用户注册功能中曾使用HTML表单，经过HTTP的POST请求和用户控制器的`create`动作提交。创建微博的实施方式与之类似，只是不必在一个独立的`/microposts/new`页面，而是直接在根页面`/`上操作。

到目前为止，根页面上只有一个注册按钮，对已经注册和登录的用户没有意义。这里将更新根页面设计，根据访客的登录状态提供不同的注册或发微博的功能页面。首先更新微博控制器的`create`动作：
`app/controllers/microposts_controller.rb`
```
class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  # 需要更新的仅是`create`动作
  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.save
      flash[:success] = "Micropost created!"
      redirect_to root_url
    else
      render 'static_pages/home'
    end
  end

  def destroy
  end

  private
    # 这里限制创建微博的动作，只允许修改微博内容
    def micropost_params
      params.require(:micropost).permit(:content)
    end
end
```

更新根页面静态设计代码：
`app/views/static_pages/home.html.erb`
```
<% if logged_in? %>
  # 如果用户已经登录则显示以下代码定义的内容
  <div class="row">
    <aside class="col-md-4">
      # 在一个页面章节显示用户信息
      <section class="user_info">
        <%= render 'shared/user_info' %>
      </section>
      # 在另一个页面章节显示微博表单
      <section class="micropost_form">
        <%= render 'shared/micropost_form' %>
      </section>
    </aside>
  </div>
<% else %>
  # 如果用户没有登录则显示原来的如下内容
  <div class="center jumbotron">
    <h1>Welcome to the Sample App</h1>

    <h2>
      This is the home page for the
      <a href="https://www.railstutorial.org/">Ruby on Rails Tutorial</a>
      sample application.
    </h2>

    <%= link_to "Sign up now!", signup_path, class: "btn btn-lg btn-primary" %>
  </div>

  <%= link_to image_tag("rails.png", alt: "Rails logo"),
              'http://rubyonrails.org/' %>
<% end %>
```

以上更新涉及到`user_info`代码块，这里定义如下：
`app/views/shared/_user_info.html.erb`
```
# 创建一个到当前已登录用户简介页面的头像链接
<%= link_to gravatar_for(current_user, size: 50), current_user %>
# 以当前用户名为内容的一级标题
<h1><%= current_user.name %></h1>
# 链接到当前已登录用户简介页面的链接
<span><%= link_to "view my profile", current_user %></span>
# 显示当前已登录用户的微博数量，自动根据数量设置复数形式
<span><%= pluralize(current_user.microposts.count, "micropost") %></span>
```

另一个微博表单代码块定义如下：
`app/views/shared/_micropost_form.html.erb`
```
# 为微博对象创建表单
<%= form_for(@micropost) do |f| %>
  <%= render 'shared/error_messages', object: f.object %>
  # 在表单的文本区域组件处生成微博对象的内容属性
  <div class="field">
    <%= f.text_area :content, placeholder: "Compose new micropost..." %>
  </div>
  # 使用POST方法提交表单，使用预定义的CSS类套用格式
  <%= f.submit "Post", class: "btn btn-primary" %>
<% end %>
```

以上微博表单代码块中涉及的微博对象需要在静态页面控制器中创建：
`app/controllers/static_pages_controller.rb`
```
class StaticPagesController < ApplicationController
  def home
    # 更新如下一行代码，如果用户已登录则为之创建空的微博对象
    @micropost = current_user.microposts.build if logged_in?
  end
  ...
end
```

另外，之前生成错误信息的代码块只适用于用户，这里需要更新使其通用于用户和微博对象：
`app/views/shared/_error_messages.html.erb`
```
# 更新以下一行，原来为`@user.errors.any?`
<% if object.errors.any? %>
  <div id="error_explanation">
    <div class="alert alert-danger">
      # 更新以下一行，原来为`@user.errors.count`
      The form contains <%= pluralize(object.errors.count, "error") %>.
    </div>
    <ul>
    # 更新以下一行，原来为`@user.errors.full_messages.each`
    <% object.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
<% end %>
```

注意到原来的`@user`在这里替换为`object`，因此重用该错误信息模块的地方也需要更新。

更新用户表单的通用表单视图：
```app/views/users/_form.html.erb`
```
<%= form_for(@user) do |f| %>
  <%= render 'shared/error_messages', object: f.object %>
  ...
<% end %>
```

更新重置密码的编辑视图：
`app/views/password_resets/edit.html.erb`
```
<% provide(:title, 'Reset password') %>
<h1>Password reset</h1>
<div class="row">
  <div class="col-md-6 col-md-offset-3">
    <%= form_for(@user, url: password_reset_path(params[:id])) do |f| %>
      # 更新如下一行代码，将通用表单对象代入错误信息代码块
      <%= render 'shared/error_messages', object: f.object %>
      ...
    <% end %>
  </div>
</div>
```

运行测试，确保这部分的更改有效。

一点优化，将根页面中用户登录与否两种情况下的代码拆分到代码块：
`app/views/static_pages/home.html.erb`
```
<% if logged_in? %>
  <%= render 'shared/logged_in' %>
<% else %>
  <%= render 'shared/not_logged_in' %>
<% end %>
```

创建代码块文件：
`app/views/shared/_logged_in.html.erb`
```
  <div class="row">
    <aside class="col-md-4">
      <section class="user_info">
        <%= render 'shared/user_info' %>
      </section>
      <section class="micropost_form">
        <%= render 'shared/micropost_form' %>
      </section>
    </aside>
  </div>
```

`app/views/shared/_not_logged_in.html.erb`
```
  <div class="center jumbotron">
    <h1>Welcome to the Sample App</h1>
    <h2>
      This is the home page for the
      <a href="https://www.railstutorial.org/">Ruby on Rails Tutorial</a>
      sample application.
    </h2>
    <%= link_to "Sign up now!", signup_path, class: "btn btn-lg btn-primary" %>
  </div>

  <%= link_to image_tag("rails.png", alt: "Rails logo"), 
    'http://rubyonrails.org/' %>
```

以上操作将抽取出来的代码块放到`shared`文件夹是有原因的，答案在下一个小节的末尾。

### 更新源模型

目前主页上的微博表单已经工作正常，但除非用户自己跳转到简介页面去查看，否则无法确认更新。这里创建一个更新源的模型，让用户订阅或关注自己。因为每个用户都会至少关注自己，所以在用户模型中创建更新源动作：
`app/models/user.rb
```
class User < ApplicationRecord
  ...
  # 更新添加一下一个更新源动作
  def feed
    Micropost.where("user_id = ?", id)
  end

    private
    ...
end
```

对于实际上添加的以上仅一行代码，这里还是有必要说明如下：
* 以上代码实际上可以简化成`microposts`，使用现在的样子是为了以后添加高级功能时更新方便。
* 在`where`语句中使用问号可以将读入的参数做安全逃逸处理，避免SQL脚本注入型攻击的风险。

更新静态页面控制器，创建`@feed_items`实例来引用用户从更新源返回的微博：
`app/controllers/static_pages_controller.rb`
```
class StaticPagesController < ApplicationController
  def home
    # 将原本在第一条语句末尾的登录条件判定语句移到代码块外层
    if logged_in?
      @micropost  = current_user.microposts.build
      # 添加如下一行语句，从当前用户拿到微博更新并分页
      @feed_items = current_user.feed.paginate(page: params[:page])
    end
  end
  ...
end
```

创建更新源代码块，引用之前创建的`@feed_items`实例：
`app/views/shared/_feed.html.erb`
```
<% if @feed_items.any? %>
  # 列印微博并分页
  <ol class="microposts">
    <%= render @feed_items %></ol>
  <%= will_paginate @feed_items %>
<% end %>
```

以上更新中`render @feed_items`的操作对象是一系列微博，每个都指向如下代码块：
`app/views/microposts/_micropost.html.erb`
```
<li id="micropost-<%= micropost.id %>">
  <%= link_to gravatar_for(micropost.user, size: 50), micropost.user %>
  <span class="user"><%= link_to micropost.user.name, micropost.user %></span>
  <span class="content"><%= micropost.content %></span>
  <span class="timestamp">
    Posted <%= time_ago_in_words(micropost.created_at) %> ago.
  </span>
</li>
```
这是因为Rails知道每个微博都属于`Micropost`类，因此会自动在相应视图目录中寻找相应名字的代码块。

更新根页面视图对以登录用户的页面定制，使用之前创建的更新源代码块：
`app/views/shared/_logged_in.html.erb`
```
  <div class="row">
    <aside class="col-md-4">
      <section class="user_info">
        <%= render 'shared/user_info' %>
      </section>
      <section class="micropost_form">
        <%= render 'shared/micropost_form' %>
      </section>
    </aside>
    # 添加如下代码块，列印用户微博
    <div class="col-md-8">
      <h3>Micropost Feed</h3>
      <%= render 'shared/feed' %>
    </div>
  </div>
```

到这里，创建正常的微博没有问题，但发生如创建空微博的错误时，根页面依旧等待返回一个微博数组，因此需要更新微博控制器返回一个空白数组：
`app/controllers/microposts_controller.rb`
```
class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.save
      flash[:success] = "Micropost created!"
      redirect_to root_url
    else
      # 在这里添加如下一行代码
      @feed_items = []
      render 'static_pages/home'
    end
  end

  def destroy
  end

  private

    def micropost_params
      params.require(:micropost).permit(:content)
    end
end
```

如果之前你也有做过对根页面的代码优化，把已登录和未登录用户的页面抽取到独立代码块，那么发送空白微博时可能发生找不到模版的错误。从后台可以看到错误提示，即找不到`microposts/_logged_in`文件定义，这就是要把之前抽取出来的页面代码块放到`shared`文件夹中的原因。

另外，发送空的微博依然会导致用户微博列印为空白，这也是意料之中的事情，因为为避免程序崩溃在发布失败时我们自定义返回一个空的微博数组。在Rails服务器后台查看创建微博使用的带`insert`命令的SQL脚本，可以得到如下信息：
```
SQL (2.3ms)  INSERT INTO "microposts" ("content", "user_id", "created_at", "updated_at") VALUES (?, ?, ?, ?)  [["content", "something happens"], ["user_id", 1], ["created_at", "2019-08-21 11:32:52.973184"], ["updated_at", "2019-08-21 11:32:52.973184"]]
```

最后，通过如下Rails控制台命令可以确认多种抽取用户微博的方式`Micropost.where("user_id = ?", user.id)`， user.microposts`和`user.feed`等，结果是相同的：
```
$ rails console
> user = User.find(1)
> Micropost.where("user_id = ?", user.id) == user.microposts
=> true
> Micropost.where("user_id = ?", user.id) == user.feed
=> true
> user.microposts == user.feed
=> true
```

### 删除微博

在微博资源中添加删除功能，与用户的删除功能类似，通过一个链接实现，只对微博的创建者可见和有效。

这里首先更新微博代码块：
`app/views/microposts/_micropost.html.erb`
```
<li id="<%= micropost.id %>">
  <%= link_to gravatar_for(micropost.user, size: 50), micropost.user %>
  <span class="user"><%= link_to micropost.user.name, micropost.user %></span>
  <span class="content"><%= micropost.content %></span>
  <span class="timestamp">
    Posted <%= time_ago_in_words(micropost.created_at) %> ago.
    # 判断当前登录用户是否为微博所有者，如是则显示一个链接
    <% if current_user?(micropost.user) %>
      # 链接指向微博模型的`delete`动作，使用HTTP的`delete`方法
      <%= link_to "delete", micropost, method: :delete,
                                       data: { confirm: "You sure?" } %>
    <% end %>
  </span>
</li>
```

更新微博控制器，增加对当前用户的判断和删除动作的更新：
`app/controllers/microposts_controller.rb`
```
class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  # 添加如下一行代码，限制只有当前用户可以调用删除动作
  before_action :correct_user,   only: :destroy
  ...
  # 增加如下代码块，删除指定的微博，闪信删除成功的提示
  def destroy
    @micropost.destroy
    flash[:success] = "Micropost deleted"
    # 切换以下两行代码的注释和非注释状态，确认其作用相同
    redirect_to request.referrer || root_url
    # redirect_back(fallback_location: root_url)
  end

  private

    def micropost_params
      params.require(:micropost).permit(:content)
    end
    # 添加如下代码块，增加判断当前用户登录状态的私有方法
    def correct_user
      # 用`micropost`变量返回指定ID对应的微博，在返回值有效时重定向到根目录
      @micropost = current_user.microposts.find_by(id: params[:id])
      redirect_to root_url if @micropost.nil?
    end
end
```

以上代码中唯一需要解释的是`redirect_to request.referrer || root_url`:
* `request.referrer`指向删除动作之前的链接，目前可以是主页或用户简介页面。
* 如果以上链接不存在，即返回值为`nil`时，跳转到网站根页面的`root_url`地址。
* 以上代码与`redirect_back(fallback_location: root_url)`作用相同。

是时候去以已登录用户身份到主页和用户简介页面测试删除微博了，可以都测试一下。在Rails服务器后段可以看到类似如下信息，发起删除操作，实施删除操作，重定向到根页面：
```
Started DELETE "/microposts/289" for 127.0.0.1 at 2019-08-22 16:52:21 +0800
...
  SQL (0.7ms)  DELETE FROM "microposts" WHERE "microposts"."id" = ?  [["id", 289]]
Redirected to http://localhost:3000/
```

### 微博测试

这里将测试微博控制器和用户授权，并通过集成测试收尾。更新微博的测试样本文件定义：
`test/fixtures/microposts.yml`
```
...
ants:
  content: "Oh, is that what you want? Because that's how you get ants!"
  created_at: <%= 2.years.ago %>
  user: archer

zone:
  content: "Danger zone!"
  created_at: <%= 3.days.ago %>
  user: archer

tone:
  content: "I'm sorry. Your words made sense, but your sarcastic tone did not."
  created_at: <%= 10.minutes.ago %>
  user: lana

van:
  content: "Dude, this van's, like, rolling probable cause."
  created_at: <%= 4.hours.ago %>
  user: lana
```

更新微博控制器测试，确认用户不可以删除其他用户的微博：
`test/controllers/microposts_controller_test.rb`
```
  # 添加如下测试场景
  test "should redirect destroy for wrong micropost" do
    log_in_as(users(:michael))
    micropost = microposts(:ants)
    assert_no_difference 'Micropost.count' do
      delete micropost_path(micropost)
    end
    assert_redirected_to root_url
  end
```

新增集成测试包括，以某个用户身份登录，确认微博分页，测试发布有效和无效微博，删除微博，访问其他用户微博并确认没有删除操作链接。首先，生成测试文件：
```
$ rails generate integration_test microposts_interface
```

更新测试场景定义如下：
`test/integration/microposts_interface_test.rb`
```
require 'test_helper'
class MicropostsInterfaceTest < ActionDispatch::IntegrationTest
  # 准备一个用户
  def setup
    @user = users(:michael)
  end
  # 测试微博接口
  test "micropost interface" do
    # 以测试用户登录，导航到根页面，确认页面中存在分页模块
    log_in_as(@user)
    get root_path
    assert_select 'div.pagination'
    # 提交无效的空白内容微博，确认提交失败，即提交后微博总数不变，有错误信息
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: { content: "" } }
    end
    assert_select 'div#error_explanation'
    # 提交有效的微博，确认跳转到根页面，跟随跳转，确认页面中有刚发布的内容
    content = "This micropost really ties the room together"
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: { micropost: { content: content } }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body
    # 测试删除微博，确认页面中有删除链接，选中第一个微博，确认删除操作有效
    assert_select 'a', text: 'delete'
    first_micropost = @user.microposts.paginate(page: 1).first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end
    # 确认访问其他用户页面时，页面中没有删除链接
    get user_path(users(:archer))
    assert_select 'a', text: 'delete', count: 0
  end
  # 以下测试针对侧边栏中微博数量
  test "micropost sidebar count" do
    # 登录并导航到根页面，确认页面中包含微博数量的文字
    log_in_as(@user)
    get root_path
    assert_match "#{Micropost.count} microposts", response.body
    # 登录另一个用户并导航到根页面，确认页面中显示微博数量为零
    other_user = users(:malory)
    log_in_as(other_user)
    get root_path
    assert_match "0 microposts", response.body
    other_user.microposts.create!(content: "A micropost")
    get root_path
    assert_match FILL_IN, response.body
  end
end
```

## 微博图像

在发布文字的基础上，这里再添加上传图像的功能，涉及到两个主要组件，上传图像的表单和图像微博本身。

### 基本图像

首先，更新GemFile添加必要的依赖库，注意生产环境还需要额外的代码库：
```
source 'https://rubygems.org'
...
gem 'carrierwave',             '1.2.2'
gem 'mini_magick',             '4.7.0'
...
group :production do
  ...
  gem 'fog', '1.42'
end
```

安装必要的代码库，并生成上传图片的模块，为微博模型增加图片属性：
```
$ bundle install
$ rails generate uploader Picture
$ rails generate migration add_picture_to_microposts picture:string
$ rails db:migrate
```

更新微博模型，使用`mount_uploader`方法连接图像和模型，两个参数指向属性名称和图像上传模块：
`app/models/micropost.rb`
```
class Micropost < ApplicationRecord
  belongs_to :user
  default_scope -> { order(created_at: :desc) }
  # 微博模型中只需要更新添加以下一行代码
  mount_uploader :picture, PictureUploader
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
end
```

到这里，如果运行测试会出现错误，然而其实并没有实际的错误，只需要退出Rails服务器，重启命令行终端，再次测试就应该可以通过。

更新视图的微博表单代码块，增加图像上传功能：
`app/views/shared/_micropost_form.html.erb`
```
<%= form_for(@micropost) do |f| %>
  <%= render 'shared/error_messages', object: f.object %>
  <div class="field">
    <%= f.text_area :content, placeholder: "Compose new micropost..." %>
  </div>
  <%= f.submit "Post", class: "btn btn-primary" %>
  # 需要更新添加以下三行代码
  <span class="picture">
    <%= f.file_field :picture %>
  </span>
<% end %>
```

更新微博控制器，允许通过网页修改文本和图像内容的微博参数：
`app/controllers/microposts_controller.rb`
```
  ...
  private
    def micropost_params
      # 这里只需要更新如下一行代码
      params.require(:micropost).permit(:content, :picture)
    end
    ...
end
```

更新视图的微博代码块，使用帮助方法`image_tag`生成图像：
`app/views/microposts/_micropost.html.erb`
```
<li id="micropost-<%= micropost.id %>">
  <%= link_to gravatar_for(micropost.user, size: 50), micropost.user %>
  <span class="user"><%= link_to micropost.user.name, micropost.user %></span>
  <span class="content">
    <%= micropost.content %>
    # 这里需要更新追加如下一行代码，用来显示图片，图片不存在时不生成图像类型网页组件
    <%= image_tag micropost.picture.url if micropost.picture? %>
  </span>
  <span class="timestamp">
    Posted <%= time_ago_in_words(micropost.created_at) %> ago.
    <% if current_user?(micropost.user) %>
      <%= link_to "delete", micropost, method: :delete,
                                       data: { confirm: "You sure?" } %>
    <% end %>
  </span>
</li>
```

更新微博接口集成测试，添加对图像上传模块和功能的测试：
`test/integration/microposts_interface_test.rb`
```
    ...
    assert_select 'div.pagination'
    # 添加如下一行代码
    assert_select 'input[type=file]'
    ...
    content = "This micropost really ties the room together"
    # 更新如下代码部分
    picture = fixture_file_upload('test/fixtures/rails.png', 'image/png')
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: { micropost:
                                      { content: content,
                                        picture: picture } }
    end
    ...
```

运行测试前，拷贝测试用图片到指定位置：
```
$ cp app/assets/images/rails.png test/fixtures/
```

现在可以运行测试，并运行Rails服务器尝试上传图片。

### 图像验证

以上建立的图像上传功能对上传文件的大小和格式没有验证，用户可以上传任意大小和格式的文件。为了修补这个漏洞，需要添加在服务器端和客户端的图像认证功能。

更新图片文件上传模块，定义允许上传的图像文件扩展名：
`app/uploaders/picture_uploader.rb`
```
class PictureUploader < CarrierWave::Uploader::Base
  storage :file
  # 定义上传文件的存储位置，默认启用，不需要修改
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
  # 反注释以下语句，建立可上传文件扩展名白名单
  def extension_whitelist
    %w(jpg jpeg gif png)
  end
end
```

上传文件大小的验证在微博模型中定义，没有默认的便捷方法，需要单独定义为内部方法：
`app/models/micropost.rb`
```
class Micropost < ApplicationRecord
  ...
  # 更新添加如下语句和内部方法
  validate  :picture_size

  private

    # Validates the size of an uploaded picture.
    def picture_size
      if picture.size > 5.megabytes
        errors.add(:picture, "should be less than 5MB")
      end
    end
end
```

为控制客户端控制上传文件类型和大小，更新微博表单视图如下：
`app/views/shared/_micropost_form.html.erb`
```
<%= form_for(@micropost) do |f| %>
  <%= render 'shared/error_messages', object: f.object %>
  <div class="field">
    <%= f.text_area :content, placeholder: "Compose new micropost..." %>
  </div>
  <%= f.submit "Post", class: "btn btn-primary" %>
  <span class="picture">
    # 更新如下一行代码，添加文件上传类型限制
    <%= f.file_field :picture, accept: 'image/jpeg,image/gif,image/png' %>
  </span>
<% end %>

# 添加如下脚本，检测网页对象变化并触发对文件大小的检测
<script type="text/javascript">
  $('#micropost_picture').bind('change', function() {
    var size_in_megabytes = this.files[0].size/1024/1024;
    if (size_in_megabytes > 5) {
      alert('Maximum file size is 5MB. Please choose a smaller file.');
    }
  });
</script>
```

注意，客户端的图像验证没有强制作用，用户可以通过修改网页代码或向网页直接发送上传请求，绕过客户端验证，因此服务器端的验证相对更有必要。现在可以尝试上传格式或容量不合要求的文件，检查应用是否可以正确响应。

### 图像调整

为优化图片的显示，特别是将尺寸过大的文件调整到合适尺寸，这里在MacOS开发环境安装`ImageMagick`程序：
```
$ sudo yum install -y ImageMagick
$ brew install imagemagick
```

更新图片文件上传模块的配置文件，将长或宽大于400像素的图片缩放到400像素，对更小的图片不做处理：
`app/uploaders/picture_uploader.rb`
```
class PictureUploader < CarrierWave::Uploader::Base
  # 通过反注释添加如下第一行代码，手动添加第二行代码
  include CarrierWave::MiniMagick
  process resize_to_limit: [400, 400]
  ...
end
```

目前运行测试会遇到错误，添加初始化配置文件，在测试中跳过图像调整：
`config/initializers/skip_image_resizing.rb`
```
if Rails.env.test?
  CarrierWave.configure do |config|
    config.enable_processing = false
  end
end
```

然而我并没有遇到图像调整相关的测试错误，所以添加但注释掉了以上文件的内容。现在可以运行Rails服务器，验证上传大尺寸文件会被自动调整和缩放到合适大小。

### 生产环境

之后的部分是配置使用AWS的云存储来保存图片，由于不适用于中国内地就不再介绍，有兴趣可以参考教程原文的最后部分。这里依旧使用本地文件方式保存上传的图片，并收尾如下：
```
# 提交合并推送代码到在线文档库
$ rails test
$ git add -A
$ git commit -m "Add user microposts"
$ git checkout master
$ git merge user-microposts
$ git push
# 发布到Heroku
# 如果有丢失heroku快捷方式运行`$ heroku git:remote -a <heroku_app_name>`
$ git push heroku
$ heroku pg:reset DATABASE
$ heroku run rails db:migrate
$ heroku run rails db:seed
```

现在可以到Heroku上部署的生产环境测试本节添加的微博功能，祝各位好运。

## 参考

1. PostgreSQL推荐使用可变或无限容量的数据类型以保证更高运行效率：
https://www.postgresql.org/docs/9.1/datatype-character.html
2. 本节原始官方教程：
https://www.railstutorial.org/book/user_microposts

# 第十四章 关注用户

教程原址：https://www.railstutorial.org/book/following_users

这一章添加的功能允许用户相互关注，在关注方的主页显示被关注方更新的微博。这里将先后建立用户关系模型、网页接口和完整的状态更新源功能。应用场景如下：
1. 一个用户从自己的简介页面出发，到用户列表页面。
2. 选择另一个用户，打开后者的简介页面，并关注后者。
3. 后者简介页面中的关注选项变为取消关注选项。
4. 前者的关注对象和后者的关注人计数器各加一。
5. 前者的根页面中，可以看到后者发布的微博。

以上场景基于一个新建的关系模型，其中包含关注者和被关注者的用户ID，通过该基础关系模型可以进一步生成主动关注和被动被关注的用户关系模型。首先生成关系模型：
```
$ rails generate model Relationship follower_id:integer followed_id:integer
```

为关注者和被关注者，以及两者唯一关系建立索引，在实施迁移前修改数据库迁移定义文件：
`db/migrate/[timestamp]_create_relationships.rb`
```
class CreateRelationships < ActiveRecord::Migration[5.0]
  def change
    create_table :relationships do |t|
      t.integer :follower_id
      t.integer :followed_id
      t.timestamps
    end
    # 添加以下三行代码
    add_index :relationships, :follower_id
    add_index :relationships, :followed_id
    add_index :relationships, [:follower_id, :followed_id], unique: true
  end
end
```

实施迁移：
```
$ rails db:migrate
```

### 用户关系

更新用户模型，建立一对多的主动关系：
`app/models/user.rb`
```
class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  # 更新添加以下三行代码
  has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "follower_id",
                                  dependent:   :destroy
  ...
end
```

相应的，更新关系模型定义，关联到用户模型：
`app/models/relationship.rb`
```
class Relationship < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"
end
```

与一对多的用户微博关系不同，主动关系模型对应的类名（Relationship）与关系名（active_relationships）不一致，因此这里需要特别声明类名称，并指明外键对应的属性名，最后由于删除用户也会删除相应的关系，所以对删除操作也做了依赖关系设定。

在一对多的用户微博关系中，指定的`microposts`是微博对象在数据库中的表名称，该关系定义在`user`用户模型中，因此Rails可以自动在数据库的微博表中自动查找属性值为`user_id`的列并创建外部键值关系。主动关系虽然同样定义在用户模型中，但却通过关系模型所关联的数据库关系表格创建外键，因此也需要在关系模型中特别定义反向到用户模型的所属关系。即：
* 一对多微博关系：用户模型->微博表格（用户ID外键自动创建）
* 一对多用户主动关系：用户模型->关系模型->关系表格（手动指定关注者ID和被关注者ID外键）

以上关系设定产生如下可用方法：
```
方法                                                       / 目的
active_relationship.follower                              / 返回关注者
active_relationship.followed                              / 返回被关注者
user.active_relationships.create(followed_id: <user.id>)  / 与被关注者建立主动关系
user.active_relationships.create!(followed_id: <user.id>) / 同上，强制执行
user.active_relationships.build(followed_id: <user.id>)   / 返回主动关系对象
```

为验证关系模型，更新关系模型测试：
`test/models/relationship_test.rb`
```
require 'test_helper'

class RelationshipTest < ActiveSupport::TestCase

  def setup
    @relationship = Relationship.new(follower_id: users(:michael).id,
                                     followed_id: users(:archer).id)
  end

  test "should be valid" do
    assert @relationship.valid?
  end

  test "should require a follower_id" do
    @relationship.follower_id = nil
    assert_not @relationship.valid?
  end

  test "should require a followed_id" do
    @relationship.followed_id = nil
    assert_not @relationship.valid?
  end
end
```

以上测试并不复杂，准备基于两个用户关注和被关注的关系，验证关系有效，再分别设置关注或被关注用户ID为空，验证关系无效。为增加有效性检测，更新关系模型定义：
`app/models/relationship.rb`
```
class Relationship < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"
  # 更新追加以下两行代码
  validates :follower_id, presence: true
  validates :followed_id, presence: true
end
```

注意，默认创建的关系模型测试用数据违反了关系模型的唯一性要求，这里可以删除或注释掉：
`test/fixtures/relationships.yml`
```
# one:
#   follower_id: 1
#   followed_id: 1

# two:
#   follower_id: 1
#   followed_id: 1
```

现在运行测试，确认可以通过。

### 关注用户

之前创建了外键，现在要使用外键建立关注关系，更新用户模型如下：
`app/models/user.rb`
```
class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "follower_id",
                                  dependent:   :destroy
  # 更新如下一行代码
  has_many :following, through: :active_relationships, source: :followed
  ...
end
```

用户通过关系模型可以关注多个其他用户，默认使用如下命令：
```
has_many :followeds, through: :active_relationships
```
即通过之前创建的主动关系反向查找以当前用户ID为外键的对象。Rails可以自动以`followeds`的单数形式生成需要查找的外键名称`followed_id`。只是以上默认的命名规则产生的方法名称为`user.followeds`，有些奇怪，所以实际上使用了`following`为名称，而指定用`source: followeds`生成实际查找的字段名。

经过添加以上命令，有如下方法可用：
```
user.following.include?(<user.id>) / 查看用户关注的对象中是否包含指定ID的用户
user.following.find(<user.id>)     / 查找到用户关注的指定ID用户并返回
user.following << <user.id>        / 添加指定ID的用户到当前用户的关注对象列表
user.following.delete(<user.id>)   / 从当前用户关注对象列表删除指定ID的用户
```

在进一步完善关注和取消关注的功能前，先更新用户模型测试：
`test/models/user_test.rb`
```
require 'test_helper'
class UserTest < ActiveSupport::TestCase
  ...
  test "should follow and unfollow a user" do
    # 准备两个用户
    michael = users(:michael)
    archer  = users(:archer)
    # 确认没有关注关系
    assert_not michael.following?(archer)
    # 发起关注
    michael.follow(archer)
    # 确认关注关系
    assert michael.following?(archer)
    # 取消关注关系
    michael.unfollow(archer)
    # 确认没有关注关系
    assert_not michael.following?(archer)
  end
end
```

现在运行测试当然会失败，为通过测试更新用户模型：
`app/models/user.rb`
```
class User < ApplicationRecord
  ...
  # 关注用户
  def follow(other_user)
    following << other_user
  end
  # 取消关注用户
  def unfollow(other_user)
    following.delete(other_user)
  end
  # 确认当前用户是否在关注指定用户
  def following?(other_user)
    following.include?(other_user)
  end

  private
  ...
end
```

现在运行测试，确认可以通过。

### 关注者

与之前添加关注的模型和方法类似，查询关注者依赖被动关系模型，更新用户模型如下：
`app/models/user.rb`
```
class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  has_many :active_relationships,  class_name:  "Relationship",
                                   foreign_key: "follower_id",
                                   dependent:   :destroy
  # 更新添加如下三行代码，注意只是更改了关系名称，和外键名称
  has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy
  has_many :following, through: :active_relationships,  source: :followed
  # 使用外键查询相关用户的方法也是类似
  has_many :followers, through: :passive_relationships, source: :follower
  ...
end
```

更新用户模型测试：
`test/models/user_test.rb`
```
require 'test_helper'
class UserTest < ActiveSupport::TestCase
  ...
  test "should follow and unfollow a user" do
    michael  = users(:michael)
    archer   = users(:archer)
    assert_not michael.following?(archer)
    michael.follow(archer)
    assert michael.following?(archer)
    # 更新添加如下一行代码，确认被关注用户的关注者中有关注者
    assert archer.followers.include?(michael)
    michael.unfollow(archer)
    assert_not michael.following?(archer)
  end
end
```

测试，确认目前所有功能正常。

## 网页界面

### 样本数据

更新数据库种子文件，让第一个用户关注3到51号用户，同时得到4到41号用户的关注：
`db/seeds.rb`
```
...
# Following relationships
users = User.all
user  = users.first
following = users[2..50]
followers = users[3..40]
following.each { |followed| user.follow(followed) }
followers.each { |follower| follower.follow(user) }
```

重置数据库并生成测试用数据：
```
$ rails db:migrate:reset
$ rails db:seed
```

通过Rails控制台验证测试数据：
```
$ rails console
> User.first.followers.count 
=> 38
> User.first.following.count
=> 49
```

### 关注状态

在登录用户的根页面，发布微博的表单和用户简介之间，插入关注用户和被关注用户的状态信息。作为两个独立的链接，分别跳转到关注的用户和关注者用户列表。为创建这两个链接，更新路由：
`config/routes.rb`
```
Rails.application.routes.draw do
  root   'static_pages#home'
  get    '/help',    to: 'static_pages#help'
  get    '/about',   to: 'static_pages#about'
  get    '/contact', to: 'static_pages#contact'
  get    '/signup',  to: 'users#new'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  # 更新以下代码段
  resources :users do
    member do
      get :following, :followers
    end
  end
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :microposts,          only: [:create, :destroy]
end
```

以上更新代码段中的`member`方法为每个用户成员创建两个可以通过GET方法访问的链接，链接如下：
* /users/<user.id>/following
* /users/<user.id>/followers

如果其他不变，将以上更新代码段中的`member`方法换成`collection`方法，则产生如下链接：
* /users/following
* /users/followers

接着，创建显示关注对象和关注者状态链接的代码片段：
`app/views/shared/_stats.html.erb`
```
<% @user ||= current_user %>
<div class="stats">
  <a href="<%= following_user_path(@user) %>">
    <strong id="following" class="stat">
      <%= @user.following.count %>
    </strong>
    following
  </a>
  <a href="<%= followers_user_path(@user) %>">
    <strong id="followers" class="stat">
      <%= @user.followers.count %>
    </strong>
    followers
  </a>
</div>
```

更新根页面登录用户的静态文件定义，添加对关注状态代码片段的引用：
`app/views/shared/_logged_in_home.html.erb`
```
  <div class="row">
    <aside class="col-md-4">
      <section class="user_info">
        <%= render 'shared/user_info' %>
      </section>
      # 添加如下三行代码，引用关注状态代码片段
      <section class="stats">
        <%= render 'shared/stats' %>
      </section>
      <section class="micropost_form">
        <%= render 'shared/micropost_form' %>
      </section>
    </aside>
    <div class="col-md-8">
      <h3>Micropost Feed</h3>
      <%= render 'shared/feed' %>
    </div>
  </div>
```

为添加关注状态格式的定义，更新自定义格式：
`app/assets/stylesheets/custom.scss`
```
...
/* sidebar */
...
.gravatar {
  float: left;
  margin-right: 10px;
}

.gravatar_edit {
  margin-top: 15px;
}

.stats {
  overflow: auto;
  margin-top: 0;
  padding: 0;
  a {
    float: left;
    padding: 0 10px;
    border-left: 1px solid $gray-lighter;
    color: gray;
    &:first-child {
      padding-left: 0;
      border: 0;
    }
    &:hover {
      text-decoration: none;
      color: blue;
    }
  }
  strong {
    display: block;
  }
}

.user_avatars {
  overflow: auto;
  margin-top: 10px;
  .gravatar {
    margin: 1px 1px;
  }
  a {
    padding: 0;
  }
}

.users.follow {
  padding: 0;
}

/* forms */
...
```

### 关注按钮

为了在其他用户简介页面上操作关注与取消关注的操作，创建关注和取消关注的按钮代码片段。

以下生成关注按钮的代码片段，发出POST请求，创建一个主动关系，并使用隐藏对象将`followed_id`传递给控制器：
`app/views/users/_follow.html.erb`
```
<%= form_for(current_user.active_relationships.build) do |f| %>
  <div><%= hidden_field_tag :followed_id, @user.id %></div>
  <%= f.submit "Follow", class: "btn btn-primary" %>
<% end %>
```

以下生成取消关注按钮的代码片段，找到一个主动关系，并发出删除请求：
`app/views/users/_unfollow.html.erb`
```
<%= form_for(current_user.active_relationships.find_by(followed_id: @user.id),
             html: { method: :delete }) do |f| %>
  <%= f.submit "Unfollow", class: "btn" %>
<% end %>
```

关注和取消关注的按钮实际上是需要配置路由并连接动作的，这里更新路由：
`config/routes.rb`
```
Rails.application.routes.draw do
  # 更新添加如下一行代码
  resources :relationships,       only: [:create, :destroy]
end
```

将关注或取消关注的按钮代码片段放到关注表单的代码片段中：
`app/views/users/_follow_form.html.erb`
```
# 比较当前登录用户与调用该代码片段的页面所传入的用户变量
# 如果二者为同一用户则什么也不做，否则判断二者是否有关注
<% unless current_user?(@user) %>
  <div id="follow_form">
  # 如果当前登录用户有关注页面传入的用户变量，则生成取消关注按钮
  <% if current_user.following?(@user) %>
    <%= render 'unfollow' %>
  <% else %>
  # 否则，即没有关注关系，则生成关注按钮
    <%= render 'follow' %>
  <% end %>
  </div>
<% end %>
```

更新用户简介视图，放入关注状态和关注表单对象：
`app/views/users/show.html.erb`
```
<% provide(:title, @user.name) %>
<div class="row">
  <aside class="col-md-4">
    <section>
      <h1>
        <%= gravatar_for @user %>
        <%= @user.name %>
      </h1>
    </section>
    # 在这里插入关注状态
    <section class="stats">
      <%= render 'shared/stats' %>
    </section>
  </aside>
  <div class="col-md-8">
    # 在这里插入关注表单，即根据用户关系放置关注或取消关注的按钮
    <%= render 'follow_form' if logged_in? %>
    <% if @user.microposts.any? %>
      <h3>Microposts (<%= @user.microposts.count %>)</h3>
      <ol class="microposts">
        <%= render @microposts %>
      </ol>
      <%= will_paginate @microposts %>
    <% end %>
  </div>
</div>
```

### 关注对象和关注者页面

相关页面包含当前登录用户简介和一个用户列表，分别是关注对象和关注者列表。两个页面都只对登录用户可用，先写出测试代码，更新用户控制器测试：
`test/controllers/users_controller_test.rb`
```
require 'test_helper'
class UsersControllerTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    @other_user = users(:archer)
  end
  ...

  test "should redirect following when not logged in" do
    get following_user_path(@user)
    assert_redirected_to login_url
  end

  test "should redirect followers when not logged in" do
    get followers_user_path(@user)
    assert_redirected_to login_url
  end
end
```

更新用户控制器：
`app/controllers/users_controller.rb`
```
class UsersController < ApplicationController
  # 添加关注对象和关注者的动作到登录条件限制列表
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy,
                                        :following, :followers]
  ...
  # 准备标题、当前登录用户和关注用户变量，生成用户列表
  def following
    @title = "Following"
    @user  = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end
  # 准备标题、当前登录用户和关注者变量，生成用户列表
  def followers
    @title = "Followers"
    @user  = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end

  private
  ...
end
```

创建显示关注用户和关注者页面的模版文件，即前文中生成页面使用的模版：
`app/views/users/show_follow.html.erb`
```
<% provide(:title, @title) %>
<div class="row">
  <aside class="col-md-4">
    <section class="user_info">
      <%= gravatar_for @user %>
      <h1><%= @user.name %></h1>
      <span><%= link_to "view my profile", @user %></span>
      <span><b>Microposts:</b> <%= @user.microposts.count %></span>
    </section>
    <section class="stats">
      <%= render 'shared/stats' %>
      <% if @users.any? %>
        <div class="user_avatars">
          <% @users.each do |user| %>
            <%= link_to gravatar_for(user, size: 30), user %>
          <% end %>
        </div>
      <% end %>
    </section>
  </aside>
  <div class="col-md-8">
    <h3><%= @title %></h3>
    <% if @users.any? %>
      <ul class="users follow">
        <%= render @users %>
      </ul>
      <%= will_paginate %>
    <% end %>
  </div>
</div>
```

执行测试，确认到目前为止的代码无错。

生成关注功能的集成测试：
```
$ rails generate integration_test following
```

更新关注集成测试：
`test/integration/following_test.rb`
```
require 'test_helper'

class FollowingTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    log_in_as(@user)
  end

  test "following page" do
    get following_user_path(@user)
    assert_not @user.following.empty?
    assert_match @user.following.count.to_s, response.body
    @user.following.each do |user|
      assert_select "a[href=?]", user_path(user)
    end
  end

  test "followers page" do
    get followers_user_path(@user)
    assert_not @user.followers.empty?
    assert_match @user.followers.count.to_s, response.body
    @user.followers.each do |user|
      assert_select "a[href=?]", user_path(user)
    end
  end
end
```

更新关系的集成测试样本数据：
`test/fixtures/relationships.yml`
```
one:
  follower: michael
  followed: lana

two:
  follower: michael
  followed: malory

three:
  follower: lana
  followed: michael

four:
  follower: archer
  followed: michael
```

运行测试，确认可以通过。

### 关注按钮

生成关系控制器：
```
$ rails generate controller Relationships
```

完善关系控制器测试场景：
`test/controllers/relationships_controller_test.rb`
```
require 'test_helper'

class RelationshipsControllerTest < ActionDispatch::IntegrationTest

  test "create should require logged-in user" do
    assert_no_difference 'Relationship.count' do
      post relationships_path
    end
    assert_redirected_to login_url
  end

  test "destroy should require logged-in user" do
    assert_no_difference 'Relationship.count' do
      delete relationship_path(relationships(:one))
    end
    assert_redirected_to login_url
  end
end
```

更新关系控制器：
`app/controllers/relationships_controller.rb`
```
class RelationshipsController < ApplicationController
  before_action :logged_in_user

  def create
    user = User.find(params[:followed_id])
    current_user.follow(user)
    redirect_to user
  end

  def destroy
    user = Relationship.find(params[:id]).followed
    current_user.unfollow(user)
    redirect_to user
  end
end
```

测试，确保可以通过。

### 优化按钮

更新关注按钮，使用Ajax：
`app/views/users/_follow.html.erb`
```
<%= form_for(current_user.active_relationships.build, remote: true) do |f| %>
  <div><%= hidden_field_tag :followed_id, @user.id %></div>
  <%= f.submit "Follow", class: "btn btn-primary" %>
<% end %>
```

更新关注按钮，使用Ajax：
`app/views/users/_unfollow.html.erb`
```
<%= form_for(current_user.active_relationships.find_by(followed_id: @user.id),
             html: { method: :delete },
             remote: true) do |f| %>
  <%= f.submit "Unfollow", class: "btn" %>
<% end %>
```

更新关系控制器，响应Ajax请求：
`app/controllers/relationships_controller.rb`
```
class RelationshipsController < ApplicationController
  before_action :logged_in_user

  def create
    @user = User.find(params[:followed_id])
    current_user.follow(@user)
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end

  def destroy
    @user = Relationship.find(params[:id]).followed
    current_user.unfollow(@user)
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end
end
```

更新应用程序配置：
`config/application.rb`
```
require File.expand_path('../boot', __FILE__)
...
module SampleApp
  class Application < Rails::Application
    ...
    # 在远程表单中包含认证令牌
    config.action_view.embed_authenticity_token_in_remote_forms = true
  end
end
```

创建嵌入了JS的Ruby命令，创建关注关系：
`app/views/relationships/create.js.erb`
```
$("#follow_form").html("<%= escape_javascript(render('users/unfollow')) %>");
$("#followers").html('<%= @user.followers.count %>');
```

创建嵌入了JS的Ruby命令，删除关注关系：
`app/views/relationships/destroy.js.erb`
```
$("#follow_form").html("<%= escape_javascript(render('users/follow')) %>");
$("#followers").html('<%= @user.followers.count %>');
```

### 测试关注

更新关注功能的集成测试：
`test/integration/following_test.rb`
```
require 'test_helper'

class FollowingTest < ActionDispatch::IntegrationTest

  def setup
    @user  = users(:michael)
    @other = users(:archer)
    log_in_as(@user)
  end
  ...
  test "should follow a user the standard way" do
    assert_difference '@user.following.count', 1 do
      post relationships_path, params: { followed_id: @other.id }
    end
  end

  test "should follow a user with Ajax" do
    assert_difference '@user.following.count', 1 do
      post relationships_path, xhr: true, params: { followed_id: @other.id }
    end
  end

  test "should unfollow a user the standard way" do
    @user.follow(@other)
    relationship = @user.active_relationships.find_by(followed_id: @other.id)
    assert_difference '@user.following.count', -1 do
      delete relationship_path(relationship)
    end
  end

  test "should unfollow a user with Ajax" do
    @user.follow(@other)
    relationship = @user.active_relationships.find_by(followed_id: @other.id)
    assert_difference '@user.following.count', -1 do
      delete relationship_path(relationship), xhr: true
    end
  end
end
```

运行测试，确认通过：

## 状态更新源

目前，在用户简介和已登录用户主页上显示的微博列表只包含登录用户自身发布的微博。这里将完善微博的状态更新源，使其包含当前用户并其所有关注用户发布的微博，并按逆序排列以保证最新的在最前。

回忆之前创建的关系测试数据样本：
`test/fixtures/relationships.yml`
```
one:
  follower: michael
  followed: lana

two:
  follower: michael
  followed: malory

three:
  follower: lana
  followed: michael

four:
  follower: archer
  followed: michael
```
在以上第一个测试用样本数据中，定义了`michael`关注`lana`，但四个样本都没有定义`archer`关注`michael`。

基于以上样本数据，更新用户模型测试，定义三个测试场景：
`test/models/user_test.rb`
```
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  ...
  test "feed should have the right posts" do
    michael = users(:michael)
    archer  = users(:archer)
    lana    = users(:lana)
    # 确认michael可以拿到关注用户lana的微博更新
    lana.microposts.each do |post_following|
      assert michael.feed.include?(post_following)
    end
    # 确认michael可以拿到自己的微博更新
    michael.microposts.each do |post_self|
      assert michael.feed.include?(post_self)
    end
    # 确认michael不会拿到未关注用户archer的微博更新
    archer.microposts.each do |post_unfollowed|
      assert_not michael.feed.include?(post_unfollowed)
    end
  end
end
```

更新用户模型的`feed`方法，返回自身和关注用户的微博：
`app/models/user.rb`
```
class User < ApplicationRecord
  ...
  # 更新如下代码块
  def feed
    Micropost.where("user_id IN (?) OR user_id = ?", following_ids, id)
  end
  ...
end
```
以上更新的命令会由Rails处理生成相应的SQL查询语句，由于在用户模型内部，`following_ids`和`id`自动指向调用该方法的用户实例所关注的用户ID和其自身ID，验证如下：
```
$ rails console
> user = User.find(1)
User Load (0.2ms)  SELECT  "users".* FROM "users" WHERE "users"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
irb(main):002:0> user.id
=> 1
irb(main):003:0> user.following_ids
SELECT "users"."id" FROM "users" INNER JOIN "relationships" ON "users"."id" = "relationships"."followed_id" WHERE "relationships"."follower_id" = ?  [["follower_id", 1]]
=> [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51]
```
注意Rails对用户`following_ids`属性的自动生成，这是由之前定义的关系模型帮助完成的。

运行测试，确认可以通过。

### 性能优化

目前，如验证代码中所示，`user.following_ids`已经从数据库完成提取出来，进一步的操作在数据库外部进行，在关注用户数量过多时会发生性能问题。更有效的方法是将整个SQL查询语句完整的放入代码中，不在两次SQL查询间留空隙：

更新用户模型：
`app/models/user.rb`
```
class User < ApplicationRecord
  ...
  # Returns a user's status feed.
  def feed
    following_ids = "SELECT followed_id FROM relationships
                     WHERE  follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
  end
  ...
end
```

更新关注功能的集成测试：
`test/integration/following_test.rb`
```
require 'test_helper'

class FollowingTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    log_in_as(@user)
  end
  ...
  test "feed on Home page" do
    get root_path
    @user.feed.paginate(page: 1).each do |micropost|
      assert_match CGI.escapeHTML(micropost.content), response.body
    end
  end
end
```

## 收尾和其他

惯例的收尾，发布到代码库和Heroku生产环境：
```
$ rails test
$ git add -A
$ git commit -m "Add user following"
$ git checkout master
$ git merge following-users
$ git push
$ git push heroku
$ heroku pg:reset DATABASE --confirm
$ heroku run rails db:migrate
$ heroku run rails db:seed
```

这个教程在此结束，提供如下扩展资源：
* https://www.learnenough.com/story
* http://launchschool.com/railstutorial
* http://turing.io/
* http://bloc.io/
* http://www.thefirehoseproject.com/?tid=HARTL-RAILS-TUT-EB2&pid=HARTL-RAILS-TUT-EB2
* http://www.thinkful.com/a/railstutorial
* https://pragmaticstudio.com/refs/railstutorial
* https://tutorials.railsapps.org/hartl

另外，愿教程的作者已经在准备更新，基于Rails6平台，可以保持关注，希望保持免费和开放。最后的最后，我发布到Heroku的程序链接如下，欢迎测试：https://ror2019.herokuapp.com/
