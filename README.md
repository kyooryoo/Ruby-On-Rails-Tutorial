# Ruby on Rails Tutorial - sample app

This is the sample application for
[*Ruby on Rails Tutorial*](https://www.railstutorial.org/)

## License

All source code is available jointly under the MIT and the Beerware License.

## Getting started

To get started with the app, clone the repo, then:
install the gems, migrate the database, run the test, and run the app:

```
$ bundle install --without production
$ rails db:migrate
$ rails test
$ rails server
```

For more information, see the
[*Ruby on Rails Tutorial* book](https://www.railstutorial.org/book).

本节完成用户资源的其他REST动作，添加包括编辑、更新、列印和删除操作。首先，添加允许用户修改自身简介的功能，同时强制对该操作开启认证授权。之后，添加列印用户的功能，涉及到抽样数据和分页，同样需要强制授权。最后，添加删除用户的功能，通过建立一个高权限的管理员用户类来执行。

## 切换到本地开发环境

这是与本教程无关的一段插曲。由于AWS的Cloud9是建立在AWS的虚拟机上，会多少收费一些费用。从这里开始恢复部署本地的Rails系统，并转移代码库到GitHub。首先，检查本地的环境对ruby、rails、和git是否就绪。
```
$ ruby --version
ruby 2.5.1p57 ...
$ rails --version
Rails 5.2.1
$ git --version
git version 2.20.1
```
如果有任一以上工具没有就绪，可以自行搜索或根据系统提示完成安装。接着，克隆项目文档库到本地，并上传到GitHub。
```

```
最后，尝试运行rails服务器，系统会提示运行bundle安装命令。注意，由于生产环境中配置的pg数据库在本地开发和测试中不会使用，安装反而还会遇到问题，所以在bundle安装中可以配置参数跳过生产环境的库安装。此时运行rails服务器不会报错，但导航到程序页面会遇到错误提示，需要根据提示做数据库迁移。终止rails服务器运行，迁移数据库，再重新运行rails数据库即可。

```
# 检查本地Rails是否就绪

# 登录bitbucket获取项目文档库克隆命令
$ git clone git@bitbucket.org:<your_username>/sample_app.git
# 安装依赖的库
$ bundle install --without production
# 迁移数据库
$ rails db:migrate
```

## 更新用户

编辑用户信息的方式与创建新用户类似，只是用`edit`动作而不是`new`动作生成用户视图，用`update`响应HTTP的`PATCH`请求而不是用`create`响应`POST`请求。最主要的区别是，虽然任何人都可以注册，但只有当前用户才能修改自己的简介。这里将会用`before filter`，即一个提前过滤功能实现对用户的登录状态验证。

```
# 首先创建本节的代码分支
$ git checkout -b updating-users
```

### 编辑表单

为了启用用户简介编辑视图页面，需要通过在用户控制器添加`edit`动作和在用户视图中添加`edit`视图。这里，先添加`edit`动作，涉及到从数据库中拿到相关的用户，编辑用户简介的页面URL地址为`/users/<user_id>/edit`。由于用户ID的`user_id`变量可以通过`params[:id]`引用，更新用户控制器添加`edit`动作如下：
更新的文件：app/controllers/users_controller.rb
```
class UsersController < ApplicationController
  def new
    @user = User.new
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = "Your new account is created!"
      redirect_to user_path(@user)
    else
      render 'new'
    end
  end
  
  # 新增代码开始
  def edit
    @user = User.find(params[:id])
  end
  # 新增代码结束

  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end
end
```

创建用户的编辑视图文件：
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
更新导航下拉链接项目``
app/views/layouts/_header.html.erb
```
# 原来的设定
<li><%= link_to "Settings", '#' %></li>
# 更新的结果
<li><%= link_to "Settings", edit_user_path(current_user) %></li>
```

这部分有两个残留问题，一是在编辑用户简介页面中，用户头像超链接打开的新页面是一个外部资源，目前的代码中存在安全隐患。二是目前编辑用户简介和新用户注册页面的代码中存在冗余，集中在用户信息的表单部分，可以提取出来作为单独模块。

第一个问题：
```
# 原始的链接定义如下，存在安全和性能隐患，具体参考备注部分关于`rel="noopener"`的说明
<a href="http://gravatar.com/emails" target="_blank">change</a>
# 如下添加超链接的`rel="noopener"`属性定义后，可以排除安全和新能隐患
<a href="http://gravatar.com/emails" target="_blank" rel="noopener">change</a>
```

第二个问题：
新建表单文件`app/views/users/_form.html.erb`:
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

  # 注意这里的表单按名称需要引用外部变量填充
  <%= f.submit yield(:button_text), class: "btn btn-primary" %>
<% end %>
```
更新文件`app/views/users/new.html.erb`:
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
更新文件`app/views/users/edit.html.erb`:
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

### 编辑失败

对编辑失败处理类似于注册失败，首先创建`update`动作，使用`update_attributes`方法基于提交的`params`参数更新用户，在提交信息无效的情况下`update`动作返回代表失败的`false`结果，判别式的`else`语句重新导航到编辑页面，这与`create`动作的操作流程类似。

更新文件`app/controllers/users_controller.rb`:
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
这里关于成功编辑的处理留在后面再充实，目前只是放下一个展位符。

### 集成测试

根据关于测试的最佳操作，这里自动生成集成测试的文件，并编辑添加测试场景：
```
$ rails generate integration_test users_edit
```

更新文件`test/integration/users_edit_test.rb`:
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

运行测试，检验结果：
```
$ rails test
```

### 编辑成功

这里使用测试驱动开发的TDD方法，先完成测试部分代码，模拟编辑成功情况下的流程：
更新测试文件`test/integration/users_edit_test.rb`，添加如下测试场景设计： ```
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

更新用户控制器`app/controllers/users_controller.rb`中对`update`动作的定义：
```
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      # 在成功编辑用户简介后发出闪信确认信息，重定向页面到用户简介查看窗口
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end
```

更新用户模型`app/models/user.rb`中对密码长度的定义，主要添加了条件`allow_nil: true`如下：
```
validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
```
这里不用担心对密码为空的设置会允许用户使用空密码注册，因为之前有`has_secure_password`的限定条件会对新用户注册的密码做检查，而`validates :password`只会对用户更改的信息有效，不会影响新用户注册的条件检查，可以测试验证。

现在运行测试`rails test`，可以验证之前定义的测试场景可以通过。

## 用户授权

认证过程识别用户，授权过程限制用户的权限。目前，任何用户，甚至没有登录的用户，都可以访问和更新已有用户的信息，这里我们实施的安全模型将限制只有登录用户可以修改自己的信息。

对于未登录用户，如果他们试图访问在授权后可以访问的页面，如用户简介编辑页面，应该跳转到登录页面。如果未登录用户视图访问一般用户不会被授权访问，或者不存存在的页面，应该跳转到网站主页。

更新用户控制器文件`pp/controllers/users_controller.rb`：
```
class UsersController < ApplicationController
  # 在指定的edit和update动作前要求检查用户的登录状况
  before_action :logged_in_user, only: [:edit, :update]
  ...
  private

    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end

    # Before filters
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

此时运行测试会遇到错误，因为关于用户编辑的集成测试中没有指定用户登录，这里更新如下。
更新`test/integration/users_edit_test.rb`文件中成功和失败的编辑场景定义：
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
此时再去运行测试，已经可以通过。

### 用户正确

不仅是只有登录用户可以编辑简介，且只能编辑登录用户自己的简介，为了开发这部分功能，依据测试驱动开发的TDD操作流程，先要写出测试不同用户间不可互相编辑的测试场景，为此需要准备一个新的测试用户账户：
`test/fixtures/users.yml`
```
archer:
  name: Sterling Archer
  email: duchess@example.gov
  password_digest: <%= User.digest('password') %>
```

更新用户控制器测试定义文件，添加对新增测试用户的引用，以及非本人用户编辑和更新其他用户简介的场景：
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

更新用户控制器文件，将尝试编辑他人简介的用户重定向到网站主页，这里创建一个`correct_user`动作。注意到新创建的`correct_user`动作中有用户变量`@user = User.find(params[:id])`的定义，且该动作通过`before_action`过滤器在头部做了引用，所以后面代码中`edit`和`update`动作里声明用户变量的重复语句可以省略。
`app/controllers/users_controller.rb`
```
class UsersController < ApplicationController
  before_action :logged_in_user, only: [:edit, :update]
  # 新增如下语句，为eidt和update动作添加correct_user的条件
  before_action :correct_user,   only: [:edit, :update]
  ...
  def edit
    # 因为correct_user有定义且在前面引用，这里就省略了用户变量的定义
    # @user = User.find(params[:id])
  end

  def update
    # 因为correct_user有定义且在前面引用，这里就省略了用户变量的定义
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
此时再次进行测试，可以确认所有测试项目通过。

这里再追加一个帮助方法`current_user?(user)`，用来确认指定用户是否为当前登录用户:
`app/helpers/sessions_helper.rb`
```
  def remember(user)
    ...
  end
  
  # 如果指定用户是当前登录用户则返回真
  def current_user?(user)
    user == current_user
  end

  def current_user
    ...
  end
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

目前，如果未登录用户导航到某个用户A的简介编辑页面，网站会跳转到登录页，当该用户使用用户A的凭据登录后，网页会跳转到用户A的简介页面，而不是用户A的简介编辑页面面。比较理想和友好的跳转方式是到用户A的简介编辑页面，也就是网站使用者原本打算要打开的页面。

依然按照测试驱动开发TDD的流程，先写出理想场景下的逻辑测试代码：
`test/integration/users_edit_test.rb`
```
  test "successful edit with friendly forwarding" do
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
以上测试与之前的`successful edit`测试场景类似，只是在最开始的三行代码有所不同。主要是先尝试导航到用户简介编辑页，登录，再确认的确导航到了用户简介编辑页，之后的测试项目就是简介编辑场景。

为了实现在登录后导航回登录前页面的功能，这里在会话帮助文件中定义两个方法`store_location`和`redirect_back_or`分别用于保存用户登录前的目标面和导航用户在登录后回到最初的目标页面：
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
注意，以上语句中保存URL地址使用的是`session[:var]`方法，而请求地址是从`request`对象的属性中提取，这里只限于对GET请求有效。这里的`if request.get?`确认在使用`GET`方法时才返回请求的地址，因为用户可以使用其他HTTP方法例如`POST`，`PATCH`或`DELETE`等方法在没有登录的情况下提交表单，例如手动删除了会话Cookie的时候（为什么会有这么变态的用户？）

为了使用上面创建的`store_location`方法，以便在提示用户登录前将用户请求的URL地址保存下来，更新用户控制器：
`app/controllers/users_controller.rb`
```
    def logged_in_user
      unless logged_in?
        # 这里只需要添加如下一条语句
        store_location
        flash[:danger] = "Please log in."
        redirect_to login_url
      end
    end
```
使用之前创建的`redirect_back_or`方法重新导航登录用户到原始请求URL，更新会话控制器文件：
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
注意到重定向登录用户的`redirect_back_or`方法在用户登录的动作`create`之中，需要在`redirect_back_or`方法中定义每次完成重定向后清除`session[:forwarding_url]`变量值，否则以后所有用户登录后都会导航到曾经指定重定向的页面。另外，虽然`redirect_back_or`方法中清除`session[:forwarding_url]`变量值的命令在页面跳转的`redirect_to()`命令之后，但这并不妨碍前者的运行，在遇到`return`或者`end`命令之前跳转不会实际发生。


### 拿走不谢

作为原教程的练习部分，一些功能本身并不必要却可以使程序更健壮，以后用拿走不谢做下级标题并做整理。这里第一个内容是在测试中添加对`session[:forwarding_url]`变量值清理的确认，即用户登录和跳转到原始请求的页面后，保存有原始请求的变量应该是清理干净的，否则以后其他用户登录后都会被重定向到该页面，这里更新的是用户简介编辑测试文件：
`test/integration/users_edit_test.rb`
```
  test "successful edit with friendly forwarding" do
    get edit_user_path(@user)
    log_in_as(@user)
    assert_redirected_to edit_user_url(@user)
    # 这里需要添加的测试语句仅此如下一行
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
```
这里有一个遗留问题，是关于`debugger`的，也是由于移植环境到本地才发生，基本上就是需要先安装`readline`并重新安装`ruby`：
```
$ brew install readline
$ rvm list known
$ rvm install 2.6.3
$ gem install rails 
```
基本上，安装了`readline`并重装了Ruby之后就可以用`debugger`了，只是在终端的输入自己不可见，但是可以运行。

## 列印用户

这部分创建用户主页，显示所有用户而不只是一个，从数据库中采样并分页显示，以适应可能有大量用户的情况，并为管理员准备一个界面用于删除用户。目前，所有网页访客都可以查看某个用户的简介，但显示所有用户的页面将只对注册用户开放，所以这里先要实施一个安全功能，依然按照测试驱动开发的TDD流程，先写出测试场景：
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
  # 目前获取的是全部用户，不适用生产环境，以后再做改进
  def index
    @users = User.all
  end
```

相关的视图文件需要手动创建，这里使用`each`方法遍历用户并为每个用户生成一个`li`对象：
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


### 生成用户

目前的数据库中只有一个测试用户，本节开发需要更多，当然可以到注册界面手动生成，这里介绍使用程序自动生成用户的方法。首先更新`Gemfile`文件，添加`gem 'faker', '1.7.3'`到所有环境，真实场景下应该只用于开发环境：
`Gemfile`
```
gem 'faker',                   '1.7.3'
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
重制数据库并生成样例用户，如果重制数据库的操作失败，终止Rails服务器后再尝试：
```
$ rails db:migrate:reset
$ rails db:seed
```
现在可以运行Rails服务器，登录并到用户列表页面查看效果。所有用户显示在一个页面上，在用数量过多时会有加载时间过长和不便查看的问题，以下通过分页用户显示列表解决。

### 分页用户

Rails环境下实现分页功能的模块很多，这里使用一个较常见和健壮的`will_paginate`模块，首先更新库引用：
`Gemfile`
```
gem 'will_paginate',           '3.1.6'
gem 'bootstrap-will_paginate', '1.0.0'
```
安装跟新追加的库：
```
$ bundle install
```
之后需要重启Rails服务器，以确保所有库文件正确的重新加载。接着，更新用户的`index`视图，使用可以支持分页的对象代替`User.all`，这里首先添加`will_paginate`方法：
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
这里的`will_paginate`方法了解自己是在`users`的视图中，会自动查找`@users`对象并且显示到其他页面的链接。目前这个视图还没有按照预期工作，因为用户控制器的主页动作中的变量`@users`中包含`User.all`，需要调用`paginate`方法为结果分页。例如，`User.paginate(page: 1)`默认从数据库中以每次30个的单位获取用户记录，如果`page`赋值则为`nil`则返回第一页。
```
$ rails console
> User.paginate(page:1)
  User Load (1.0ms)  SELECT  "users".* FROM "users" LIMIT ? OFFSET ?  [["LIMIT", 11], ["OFFSET", 0]]
   (0.1ms)  SELECT COUNT(*) FROM "users"
 => #<ActiveRecord::Relation [#<User id: 1, name: "Example User",
> User.paginate(page:nil)
  User Load (0.3ms)  SELECT  "users".* FROM "users" LIMIT ? OFFSET ?  [["LIMIT", 11], ["OFFSET", 0]]
   (0.1ms)  SELECT COUNT(*) FROM "users"
 => #<ActiveRecord::Relation [#<User id: 1, name: "Example User",...
```
使用该方法更新用户控制器中的`index`动作定义：
`app/controllers/users_controller.rb`
```
  def index
    @users = User.paginate(page: params[:page])
  end
```
现在可以运行Rails服务器，登录并打开用户列表页面确认分页效果。

### 测试列印

这里补充一个小测试，包括登录、访问用户列表、确认用户列表存在、确认用户分页栏存在，为了测试最后两项需要在测试数据库中准备超过三十个测试用用户账户。由于`fixture`文件支持嵌入式Ruby语言，除了特别指明增添的几个用户外，可以使用命令根据模版生成30个用户：
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
首先，生成测试文件：
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
    log_in_as(@user)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination', count: 2
    User.paginate(page: 1).each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
    end
  end
end
```
以上测试确认存在`div`带有`pagination`类定义，确认第一页上有用户存在。运行测试，确认可以通过。这里也可以进行反向测试，将用户列表界面中的分页模块注释掉，再次测试确认无法通过。
```
# 注释前
<%= will_paginate %>
# 注释后
<%#= will_paginate %>
```

### 继续优化


使用Rails的功能优化用户列表视图，首先用`render`将用户列表中的`li`对象抽取出来：
`app/views/users/index.html.erb`
```
<ul class="users">
  <% @users.each do |user| %>
    <%= render user %>
  <% end %>
</ul>
```

手动创建抽取出来的`user`模块：
`app/views/users/_user.html.erb`
```
<li>
  <%= gravatar_for user, size: 50 %>
  <%= link_to user.name, user %>
</li>
```

最后，对用户列表视图中的代码进一步简化，让Rails自己遍历用户数组`@users`并应用抽取的`user`模块：
`app/views/users/index.html.erb`
```
<ul class="users">
  <%= render @users %>
</ul>
```

完成以上改进后测试，确认程序没有问题。

## 删除用户

### 更新模型

首先，更新用户模型，添加一个识别管理员的布尔型逻辑属性`admin`:
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
这里，`:boolean`后面的`, default:false`是手动加入的，如此明确定义可以增强代码可读性，效果与默认的`nil`值相同。之后可以实施迁移，即数据库更新：
```
$ rails db:migrate
```
完成后，可以在Rails控制台中确认更新结果：
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
最后更新DB的种子文件，以便在重制数据库和重新生成数据时初始化一个管理员用户：
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
重置数据库并根据以上更新中子定义生成用户账户：
```
$ rails db:migrate:reset
$ rails db:seed
```
作为安全方面的确认，之前在通过HTTP请求可以导入的用户属性方面，已经将`admin`属性排除，否则恶意用户可以用如下更新操作将某个普通用户提升为管理员：
```
patch /users/17?admin=1
```
可以再次查看用户管理器中对用户属性参数的限制确认以上安全考量：
`app/controllers/users_controller.rb`
```
def user_params
  params.require(:user).permit(:name, :email, :password, :password_confirmation)
end
```
更新用户控制器测试定义，添加对管理员属性编辑的不可用验证：
`test/controllers/users_controller_test.rb`
```
  test "should not allow the admin attribute to be edited via the web" do
    log_in_as(@other_user)
    assert_not @other_user.admin?
    patch user_path(@other_user), params: {
                                    user: { password:              "password",
                                            password_confirmation: "password",
                                            admin: true } }
    assert_not @other_user.admin?
  end
```
运行测试，确认普通用户管理属性默认为否，尝试设置测试用户管理员属性为是，验证属性值仍为否。测试通过，好像没有问题，但是修改用户控制器对可修改属性的设定，添加`admin`属性到可修改属性列表，再次测试依然可以通过。即有意设置管理员属性可编辑后也没有能顺利编辑，这实际是一个问题，待解。

### 添加动作

更新用户列表中的单用户模块，为每个用户记录添加一个删除操作链接，只有管理员登录时可见：
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
浏览区无法原生的发出DELETE请求，Rails使用JS模拟这个操作，因此如果用户的浏览器禁用了JS会导致该删除链接不可用。如果必须支持不允许JS的浏览器，妥协方案是使用表单发送POST请求模拟DELETE操作，这个话题最后单独详述。

更新用户控制器，添加删除动作，将其加入只允许登录用户操作的动作列表：
`app/controllers/users_controller.rb`
```
  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end
```

虽然按照目前的设计，只有管理员可以看到删除操作链接，但恶意用户仍然可以通过命令行删除用户，因此这里对`destory`动作再多添加一层安全保证，确认只有管理员用户才能触发：
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
更新用户控制器测试文件，使用`delete`方法触发删除用户操作：
`test/controllers/users_controller_test.rb`
```
  test "should redirect destroy when not logged in" do
    assert_no_difference 'User.count' do
      delete user_path(@user)
    end
    assert_redirected_to login_url
  end

  test "should redirect destroy when logged in as a non-admin" do
    log_in_as(@other_user)
    assert_no_difference 'User.count' do
      delete user_path(@user)
    end
    assert_redirected_to root_url
  end
```
以上测试用`assert_no_difference`确定在尝试删除时用户数量没有减少，即在用户未登录或登录用户非管理员的情况下删除操作没有成功。验证，非登录用户发起删除用户操作时会重定向到登录界面，登录的非管理员用户尝试删除操作时会被重定向到网站主页。

以上测试对非授权用户的删除操作验证了失败，对授权的管理员用户也需要测试可以成功删除用户，由于是在用户列表页面进行，测试代码添加在用户列表的集成测试定义文件中：
`test/integration/users_index_test.rb`
```
require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest

  def setup
    @admin     = users(:michael)
    @non_admin = users(:archer)
  end

  test "index as admin including pagination and delete links" do
    log_in_as(@admin)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination'
    first_page_of_users = User.paginate(page: 1)
    first_page_of_users.each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
      unless user == @admin
        assert_select 'a[href=?]', user_path(user), text: 'delete'
      end
    end
    assert_difference 'User.count', -1 do
      delete user_path(@non_admin)
    end
  end

  test "index as non-admin" do
    log_in_as(@non_admin)
    get users_path
    assert_select 'a', text: 'delete', count: 0
  end
end
```
注意，以上测试会验证管理员用户下能够在每个用户记录中看到`delete`链接，在删除用户后用户数会减少一个，而非管理员用户在用户列表中不会看到任何`delete`字段。

最后，运行测试，应该可以通过。这里记录一个问题，关于反向测试，也就是注释掉用户控制器中的如下过滤器语句：
`app/controllers/users_controller.rb`
```
efore_action :admin_user,     only: :destroy
```
再次运行测试，应该不能通过，这样才表示该过滤器起了作用，但遗憾的是在我的环境中测试依然通过了，这里先不做排错但记录下这个问题，以后再解。

## 收尾

抱歉这一章等了这么久才更新，之前在忙别的事情。这个教程还剩四个个部分，后面的两个章节分别关于激活新注册用户和重制用户账户密码。这里收尾本章节如下：
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
因为迁移到本地，之前Heroku创建和建立的默认本地链代码库接丢失了，目前在每个命令后指定需要操作的Heroku代码库。

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