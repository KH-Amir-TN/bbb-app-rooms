# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'rails_helper'
require 'bigbluebutton_api'

describe BbbHelper do
  include BbbHelper
  include ActionView::Helpers::TranslationHelper

  let(:bbb_helper) { BigBlueButton::BigBlueButtonApi.new('http://bbb.example.com/bigbluebutton/api', 'secret', '1.0') }

  before do
    @room = create(:room)
  end

  describe 'meeting' do
    context '#running?' do
      it 'should return false when not running' do
        expect(meeting_running?).to(be(false))
      end

      it 'should return true when running' do
        allow_any_instance_of(BigBlueButton::BigBlueButtonApi).to(receive(:is_meeting_running?).and_return(true))
        expect(meeting_running?).to(be(true))
      end
    end

    context '#join_meeting_url' do
      let(:autoclose_url) { 'javascript:window.close();' }

      it 'should return correct join URL for user' do
        allow_any_instance_of(BigBlueButton::BigBlueButtonApi).to(receive(:get_meeting_info).and_return(
                                                                    meetingName: @room.name
                                                                  ))

        @user = BbbAppRooms::User.new(uid: 'uid',
                                      full_name: 'Jane Doe',
                                      first_name: 'Jane',
                                      last_name: 'Doe',
                                      email: 'jane.doe@email.com',
                                      roles: 'Administrator,Instructor,Administrator')

        endpoint = Rails.configuration.bigbluebutton_endpoint
        secret = Rails.configuration.bigbluebutton_secret
        fullname = "fullName=#{@user.full_name}"

        meeting_id = "&meetingID=#{@room.handler}"
        password = "&password=#{@room.moderator}"
        userid = "&userID=#{@user.uid}"

        encoded_params = (fullname + meeting_id + password + userid).gsub(' ', '+')
        string = "join#{encoded_params}#{secret}"

        checksum = OpenSSL::Digest.digest('sha1', string).unpack1('H*')

        expect(join_meeting_url).to(eql("#{endpoint}/join?#{encoded_params}&checksum=#{checksum}"))
      end
    end
  end

  describe 'recordings' do
    context '#delete_recording' do
      it 'deletes the recording' do
        allow_any_instance_of(BigBlueButton::BigBlueButtonApi).to(receive(:delete_recordings).and_return(
                                                                    returncode: true, deleted: true
                                                                  ))

        expect(delete_recording(Faker::IDNumber.valid))
          .to(contain_exactly([:returncode, true], [:deleted, true]))
      end
    end
  end
end
