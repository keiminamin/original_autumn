require 'bundler/setup'
Bundler.require

if development?
  ActiveRecord::Base.establish_connection("sqlite3:db/development.db")
end

class User < ActiveRecord::Base
  has_secure_password
  has_many :usergroups
  has_many :groups, through: :usergroups
  has_many :boards

end

class Usergroup < ActiveRecord::Base
    belongs_to :group
    belongs_to :user

end

class Group < ActiveRecord::Base
  has_secure_password
  has_many :usergroups
  has_many :users, through: :usergroups
  has_many :boards

end

class Board < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
end
