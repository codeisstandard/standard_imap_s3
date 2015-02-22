class Attachment < ActiveRecord::Base

  has_attached_file :file, :use_timestamp => false
  validates_attachment :file, :content_type => { :content_type => %w(application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document) }

  def save_attachment(user_id, file)

    attachment = Attachment.new
    # the actual file. paperclip handles all the heavy lifting for us by saving to S3. 
    attachment.file = file
    # how we know who this belongs to
    attachment.user_id = user_id
    attachment.file_file_name = "#{user_id}_attachment"
    
    attachment.save
    # in case you want the fully qualified path, you have to save the file first
    # then you can get the file path and resave. kinda lame but haven't figured out a
    # better way to do it
    attachment.path = attachment.file.url
    attachment.save
    attachment.id

  end
end