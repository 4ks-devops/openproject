#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'support/shared/previews'

describe WorkPackagesController, type: :controller do
  let(:user)         { FactoryGirl.create :user, admin: true }
  let(:project)      { FactoryGirl.create :project, is_public: true }

  before do
    allow(User).to receive(:current).and_return user
    expect(controller).to receive(:authorize).and_return(true)
  end

  around(:each) do |example|
    delay = Delayed::Worker.delay_jobs
    begin
      Delayed::Worker.delay_jobs = true
      example.run
    ensure
      Delayed::Worker.delay_jobs = delay
    end
  end

  describe 'create' do
    let(:create)       { post 'create', params }
    let(:work_package) { WorkPackage.find_by_subject 'genesis' }
    let(:status)       { FactoryGirl.create :status }
    let(:priority)     { FactoryGirl.create :priority }

    let(:params) do
      {
        project_id: project.id,
        work_package: {
          subject: 'genesis',
          status_id: status.id,
          priority_id: priority.id
        }
      }
    end

    let(:job) do
      Delayed::Job.all.find do |job|
        (job.payload_object.send(:work_package) rescue nil) == work_package
      end
    end

    describe 'with working email configuration' do
      before do
        create
      end

      it 'should redirect to the created work package' do
        redirect_to(work_package_path(work_package))
      end

      it 'enqueues a mail delivery job' do
        expect(job).to be_present
      end
    end

    ##
    # [regression test]
    #
    # Checks that work package creation does not lead to 500 responses
    # when the email configuration is broken as it did previously.
    describe 'with broken email configuration' do
      before do
        allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(SocketError)

        create
      end

      it 'should not result in an internal server error' do
        expect(response.status).not_to eq 500
      end

      it 'should redirect to show' do
        redirect_to(work_package_path(work_package))
      end

      describe 'notification job' do
        it 'is enqueued' do
          expect(job).to be_present
        end

        it 'fails' do
          expect{job.payload_object.perform}.to raise_error(SocketError)
        end
      end
    end
  end
end
