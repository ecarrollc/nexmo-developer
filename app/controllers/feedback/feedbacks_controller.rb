module Feedback
  class FeedbacksController < ApplicationController
    def new
    end

    def create
      @feedback = ::Feedback::Feedback.find_by_id(params['feedback_feedback']['id'])
      @feedback ||= ::Feedback::Feedback.new

      @feedback.assign_attributes(feedback_params)
      @feedback.ip = request.remote_ip

      @feedback.owner = owner
      set_email
      @feedback.owner.save!
      set_cookies

      return head 200 unless @feedback.changed?

       if @feedback.save
        respond_to do |format|
          format.js
        end
      else
        head 422
      end
    end

    private

    def set_cookies
      return unless @feedback.owner.class == ::Feedback::Author
      cookies[:feedback_author_id] = {
        value: @feedback.owner.id,
        expires: 20.years.from_now,
      }
    end

    def feedback_params
      params.require(:feedback_feedback).permit(:sentiment, :comment, :source)
    end

    def should_use_cookied_author?(author)
      # Always use the cookied author if cookies[:feedback_author_id] is present
      # but the author is not known by email
      return true if author.email.nil?

      # Always used the cookied author if present but no email has been provided
      # for this request
      return true if params['feedback_feedback']['email'].nil?

      # If the cookied author is known by email, only use it if it matches the
      # email sent in the parameters
      return true if author.email == params['feedback_feedback']['email']

      # Otherwise let's continue to try and lookup the author by email or create
      # a new author if one can not be foundd.
      false
    end

    def owner
      return current_user if current_user

      if cookies[:feedback_author_id]
        author = ::Feedback::Author.find_by_id(cookies[:feedback_author_id])
        return author if should_use_cookied_author?(author)
      end

      ::Feedback::Author.find_by_email(params['feedback_feedback']['email']) ||
      ::Feedback::Author.new
    end

    def set_email
      return if @feedback.owner.class == User
      return if params['feedback_feedback']['email'].blank?
      @feedback.owner.email = params['feedback_feedback']['email']
    end
  end
end
