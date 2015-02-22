class ProcessController < ApplicationController
  require 'net/imap'
  require 'net/http'
  require 'uri'
  require 'nokogiri'
  
  # main processor 
  def parse


    imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
    imap.login("email@email.com", "password")
    imap.select('Inbox')

    # the search syntax is kinda wonky. but you can search by date, read, unread, or by label
    # (commented out below)
    imap.search(["NOT", "SEEN"]).each do |message_id|
    #imap.search(["X-GM-LABELS", "TESTING"]).each do |message_id| 

      msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']

      # the envelope contains high level info like name, subject, and email address
      envelope = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
      subject = envelope.subject

      # the Mail object makes accessing the body a shitload easier than using imap
      mail = Mail.read_from_string msg

      # boom! look how easy it is (don't trust me? look up accessing this via imap and
      # you'll see that it's your worst damn nightmare)
      text_body = mail.text_part.body.to_s
      html_body = mail.html_part.body.to_s

      # take the attachment and save to S3
      handle_attachments(msg)

      # mark this email as read
      imap.store(message_id, "+FLAGS", [:Seen])
      # move to all mail (I'll pay someone to show me how to move to a label cuz I couldn't
      # figure that shit out)
      imap.uid_copy(message_id, "[Gmail]/All Mail")
      # delete the email (marking the email as read is probably overkill but whatever)
      imap.uid_store(message_id, "+FLAGS", [:Deleted])
      
    end

    # if you don't disconnect you'll run out of connections (IMAP works a lot like 
    # a database. you can only have so many connections)
    imap.disconnect

    # shit went haywire. kill the connection
    rescue => ex
      imap.disconnect
      raise ex
  end

  # this will take an email, loop through all attachments, and save those attachments
  # to Amazon S3  
  def handle_attachments(msg)
    mail = Mail.new(msg) 

    unless mail.attachments.blank?

      mail.attachments.each do |attachment|

        # this is the most important line of the whole thing. it takes the attachment
        # from the email, streams it, decodes it, and uses StringIO to create a file object
        # that we'll save here shortly
        file = StringIO.new(attachment.body.decoded)

        # does this user already exist?
        if User.where("EMAIL = '#{@@email}'").exists?
          user_id = User.where("EMAIL = '#{@@email}'").last.ID
        else
          user_id = User.save_user(@@first_name, @@last_name, @@email, @@phone)
        end

        user_resume = resume.save_resume(user_id, file)
        
        return user_id
      end
    end
  end
end

