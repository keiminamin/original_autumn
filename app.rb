require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require 'sinatra/activerecord'
require './models'



enable :sessions
before do
  Dotenv.load
  Cloudinary.config do |config|
    config.cloud_name = ENV['CLOUD_NAME']
    config.api_key = ENV['CLOUDINARY_API_KEY']
    config.api_secret = ENV['CLOUDINARY_API_SECRET']
  end
end
helpers do
  def current_user
    User.find_by(id: session[:user])
  end

  def current_group
    Group.find_by(id: session[:group])
  end
end

get '/' do
  @contents = Board.all.order('id desc')
  @groups = Group.all.order( 'id desc')
  # @usergroup = @groups.Usergroup.id
  # @usergroups = Usergroup.all.order( 'id desc')

  erb :index
end

get '/board' do
@contents = Board.all.order('id desc')

erb :board

end
get '/signup' do
  erb :sign_up
end

post '/signup' do
  img_url = ''
  if params[:file]
    img = params[:file]
    tempfile = img[:tempfile]
    puts tempfile.path
    upload = Cloudinary::Uploader.upload(tempfile.path)
    puts "aaaaa"
    img_url = upload['url']
  end

  user = User.create(
    name: params[:name],
    password: params[:password],
    password_confirmation: params[:password_confirmation], qr_img: img_url
  )
  if user.persisted?
    session[:user] = user.id
  end

  redirect '/'
end

get '/signin' do
  erb :sign_in
end

post '/signin' do

  user = User.find_by(name: params[:name])

  if user && user.authenticate(params[:password])
  puts "成功"


    session[:user] = user.id

  end

  redirect '/'
end

get '/signout' do
  session[:user] = nil
  redirect '/'
end

get '/groupup' do

  erb :group_up
end

post '/groupup' do
  group = Group.create(group_name: params[:group_name],password: params[:password] )

  if group.persisted?
    Usergroup.create({user_id: current_user.id,group_id: group.id})
    puts "a"

    redirect "/group/#{group.id}"
  end
  redirect'/groupup'
  puts "aaaaa"

end
get '/group/:id' do
  @group = Group.find(params[:id])
  @contents = Board.all.order('id desc')



  # @group = Group.find(params[:id])

  erb :group
end



get '/groupin' do
  erb :group_in
end

post '/groupin' do
  group = Group.find_by(group_name:
  params[:group_name])

  if group && group.authenticate(params[:password])

    Usergroup.create({user_id: current_user.id,group_id: group.id })

  redirect "/group/#{group.id}"
  end

  redirect '/groupin'
end




get '/groupout' do

  redirect '/'
end

get '/group/:id/post' do
  @group = Group.find(params[:id])
  erb :post
end

post '/group/:id/post' do
  @group = Group.find(params[:id])
    Board.create( {board_title: params[:board_title],board_content: params[:board_content],user_id: current_user.id, group_id:@group.id})


  redirect "/group/#{@group.id}"
end

post '/group/:id/:post_id/offer' do
    @group = Group.find(params[:id])
    board = Board.find(params[:post_id])
    board.custome_id = current_user.id
    board.qr_img    = current_user.qr_img
    board.save!
    redirect "/"

end

get '/group/:id/:post_id/edit' do
  @group = Group.find(params[:id])
  @content = Board.find(params[:post_id])
  erb :edit

end


post  '/board/:id' do
  content = Board.find(params[:id])
  content.board_title = params[:board_title]

  content.board_content = params[:board_content]

  content.save

  redirect '/board'

end

post '/:id/done' do
  content = Board.find(params[:id])
  content.complete = true
  content.save
  redirect '/'
end

post '/:id/evaluate' do
  content = Board.find(params[:id])
  puts current_user.point - 1
  current_user.update_attribute(:point, current_user.point - 1 )
  content.user.update_attribute(:point, content.user.point + 1)
  content.user.evaluation = params[:evaluation]
  content.save!
  content.destroy
  redirect '/'
end