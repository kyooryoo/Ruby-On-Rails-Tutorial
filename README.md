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
更新测试文件`test/integration/users_edit_test.rb`，添加如下测试场景设计：
```
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
