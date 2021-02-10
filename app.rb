require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require './models'
require 'pry'
require  'request'
require 'line/bot'

enable :sessions
before do
    unless current_user.present?
    unless request.path_info == '/'or request.path_info ==  '/signin' or  request.path_info ==  '/signup'  or request.path_info ==  '/callback' or
    request.path_info.include?("confirm")


      redirect '/'

    end

  end
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
  def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
  end
end

get '/' do
  @contents = Board.all.order('id desc')
  @groups = Group.all.order( 'id desc')
  @chats = Chat.all.order('id desc')



  # @usergroups = Usergroup.all.order( 'id desc')

  # returned_json["results"].map! do  |@content|
  # content_info = Content.find_or_create_by(track_id: content)

  # end
  erb :index
end

# post '/:id/like' do
#   content = Board.find(params[:id])
#   content.like = content.like + 1
#   content.save!
#   puts "a"
#   content.like.to_s
# end


get  '/:id/chat' do
  @content = Board.find(params[:id])
  @chats = @content.chats.all.order('id asc')

  erb :chat
end

post '/:id/chat'  do
    @content = Board.find(params[:id])
    Chat.create({message: params[:message],board_id: @content.id , user_id: current_user.id})
    redirect "/#{@content.id}/chat"
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

  @ranks = @group.users.all.order('point desc').limit(3)


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

    users = @group.users.all
    users.each do |user|
      userid = user.line_id
  message = { type: 'text', text: "グループに依頼が投稿されました。確認してみましょう
    https://shareboards-0512.herokuapp.com/" }

      client.push_message(userid, message)
    end

  redirect "/group/#{@group.id}"
end

post '/group/:id/:post_id/offer' do
    @group = Group.find(params[:id])
    board = Board.find(params[:post_id])
    board.custome_id = current_user.id
    board.qr_img    = current_user.qr_img
    board.save!

      userid = User.find_by(id: board.user_id).line_id
  message = { type: 'text', text: "#{board.user.name}さんの依頼が受け付けられました。
    https://shareboards-0512.herokuapp.com/" }

      client.push_message(userid, message)

    redirect "/"

end

get '/group/:id/:post_id/edit' do
  @group = Group.find(params[:id])
  @content = Board.find(params[:post_id])
  erb :edit

end


post  '/group/:id/:post_id' do
  @group = Group.find(params[:id])
  @content = Board.find(params[:post_id])
  @content.board_title = params[:board_title]

  @content.board_content = params[:board_content]

  @content.save

  redirect "/group/#{@group.id}"

end

post '/:id/done' do
  content = Board.find(params[:id])
  content.complete = true
  content.save

  userid = User.find_by(id: content.custome_id).line_id
  message = { type: 'text', text: "#{User.find_by(id: content.user.id).name}さんの作業が完了しました。確認してみましょう
    https://shareboards-0512.herokuapp.com/" }

      client.push_message(userid, message)

  redirect '/'
end

post '/:id/evaluate' do
  content = Board.find(params[:id])
  puts current_user.point - 1
  current_user.update_attribute(:point, current_user.point - 2 )
  content.user.update_attribute(:point, content.user.point + 2)
  # content.user.evaluation = params[:evaluation]
  content.confirm_date = Date.today
  content.save!
  userid = User.find_by(id: content.custome_id).line_id
  message = { type: 'text', text: "#{User.find_by(id: content.user_id).name}さんが確認しました。これで取引完了です
    https://shareboards-0512.herokuapp.com/" }
  redirect '/'
end

post '/callback' do

  body = request.body.read
  puts "a"
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Follow #フォローイベント
      userid = event['source']['userId']

      message = { type: 'text', text: "https://shareboards-0512.herokuapp.com/#{userid}/confirm
      こちらから認証してください" }

      client.push_message(userid, message) #push送信

    when Line::Bot::Event::Unfollow #フォロー解除(ブロック)
      userid = event['source']['userId']
      user = User.find_by(line_id: userid)
      user.destroy
    end


  #   if current_user.remained_days == -1
  #       message = { type: 'text', text: '誕生日おめでとうございます' }
  #       client.push_message(userid, message)
  #   end

  #   friend = current_user.friends

  # if current_user.friend_days == -1
  #     message = { type:'text', text:"#{friend.friend_birthday.month}月#{friend.friend_birthday.day}日。"text: "#{friend.name}さんの誕生日です。"}
  #     client.push_message(userid, message)
  #   end
  # end


  }
end

get '/:userid/confirm' do
  user = params[:userid]
  @userid = params[:userid]
  erb :confirm
end

post '/:userid/confirm' do




  user = User.find_by(name:params[:name])

    if user && user.authenticate(params[:password])
    userid = params[:userid]
    user.line_id = userid
    user.name     = params[:name]
    user.password = params[:password]

    user.save
    # if user.save!
    #   puts "できたー"
    # else
    #   puts "あああ"
    # end



    puts '認証完了'
    # redirect '/'
    # else
    #   redirect"/#{userid}/confirm "
    erb :success

    else


    redirect "/#{params[:userid]}/confirm"
    end



end
