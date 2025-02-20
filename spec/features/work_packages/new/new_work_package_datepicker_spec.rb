#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'
require 'features/page_objects/notification'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/edit_fields/edit_field'
require 'features/work_packages/work_packages_page'

describe 'New work package datepicker',
         with_settings: { date_format: '%Y-%m-%d' },
         js: true, selenium: true do
  let(:project) { create :project_with_types, public: true }
  let(:user) { create :admin }

  let(:wp_page_create) { Pages::FullWorkPackageCreate.new(project:) }
  let(:start_date) { wp_page_create.edit_field(:combinedDate) }

  before do
    login_as(user)

    wp_page_create.visit!
  end

  it 'can open and select the datepicker' do
    start_date.input_element.click

    start = (Time.zone.today - 1.day).iso8601
    start_date.activate_start_date_within_modal
    start_date.datepicker.set_date start, true

    due = (Time.zone.today + 1.day).iso8601
    start_date.activate_due_date_within_modal
    start_date.datepicker.set_date due, true

    start_date.save!
    start_date.expect_inactive!
    start_date.expect_value "#{start} - #{due}"
  end
end
