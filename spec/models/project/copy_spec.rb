#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe Project::Copy do
  describe :copy do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:copy) { Project.new }

    before do
      copy.name = "foo"
      copy.identifier = "foo"
      copy.copy(project)
    end

    subject { copy }

    it "should be able to be copied" do
      copy.should be_valid
      copy.should_not be_new_record
    end
  end

  describe :copy_attributes do
    let(:project) { FactoryGirl.create(:project_with_types) }

    let(:copy) do
      copy = Project.new
      copy.name = "foo"
      copy.identifier = "foo"
      copy
    end

    before do
      copy.send :copy_attributes, project
      copy.save
    end

    describe :types do
      subject { copy.types }

      it { should == project.types }
    end

    describe :work_package_custom_fields do
      let(:project) do
        project = FactoryGirl.create(:project_with_types)
        work_package_custom_field = FactoryGirl.create(:work_package_custom_field)
        project.work_package_custom_fields << work_package_custom_field
        project.save
        project
      end

      subject { copy.work_package_custom_fields }

      it { should == project.work_package_custom_fields }
    end

    describe :is_public do
      describe :non_public do
        let(:project) do
          project = FactoryGirl.create(:project_with_types)
          project.is_public = false
          project.save
          project
        end

        subject { copy.is_public }

        it { copy.is_public?.should == project.is_public? }
      end

      describe :public do
        let(:project) do
          project = FactoryGirl.create(:project_with_types)
          project.is_public = true
          project.save
          project
        end

        subject { copy.is_public }

        it { copy.is_public?.should == project.is_public? }
      end
    end
  end

  describe :copy_associations do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:copy) do
      copy = Project.new
      copy.name = "foo"
      copy.identifier = "foo"
      copy.copy_attributes(project)
      copy.save
      copy
    end

    describe :copy_work_packages do
      before do
        version = FactoryGirl.create(:version, :project => project)
        wp1 = FactoryGirl.create(:work_package, :project => project, :fixed_version => version)
        wp2 = FactoryGirl.create(:work_package, :project => project, :fixed_version => version)
        wp3 = FactoryGirl.create(:work_package, :project => project, :fixed_version => version)
        relation = FactoryGirl.create(:relation, :from => wp1, :to => wp2)
        wp1.parent = wp3
        wp1.category = FactoryGirl.create(:category, :project => project)
        [wp1, wp2, wp3].each { |wp| project.work_packages << wp }

        copy.send :copy_work_packages, project
        copy.save
      end

      it do
        copy.work_packages.each { |wp| wp.should(be_valid) && wp.fixed_version.should(be_nil) }
        copy.work_packages.count.should == project.work_packages.count
      end
    end

    describe :copy_timelines do
      before do
        timeline = FactoryGirl.create(:timeline, :project => project)
        # set options to nil, is known to have been buggy
        timeline.send :write_attribute, :options, nil

        copy.send(:copy_timelines, project)
        copy.save
      end

      subject { copy.timelines.count }

      it { should == project.timelines.count }
    end

    describe :copy_queries do
      before do
        FactoryGirl.create(:query, :project => project)

        copy.send(:copy_queries, project)
        copy.save
      end

      subject { copy.queries.count }

      it { should == project.queries.count }
    end

    describe :copy_members do
      describe :with_user do
        before do
          role = FactoryGirl.create(:role)
          user = FactoryGirl.create(:user, member_in_project: project, member_through_role: role)

          copy.send(:copy_members, project)
          copy.save
        end

        subject { copy.members.count }

        it { should == project.members.count }
      end

      describe :with_group do
        before do
          project.add_member! FactoryGirl.create(:group), FactoryGirl.create(:role)

          copy.send(:copy_members, project)
          copy.save
        end

        subject { copy.principals.count }

        it { should == project.principals.count }
      end
    end

    describe :copy_wiki do
      before do
        project.wiki = FactoryGirl.create(:wiki, project: project)
        project.save

        copy.send(:copy_wiki, project)
        copy.save
      end

      subject { copy.wiki }

      it { should_not == nil && should.be_valid }
    end

    describe :copy_boards do
      before do
        FactoryGirl.create(:board, project: project)

        copy.send(:copy_boards, project)
        copy.save
      end

      subject { copy.boards.count }

      it { should == project.boards.count }
    end

    describe :copy_versions do
      before do
        FactoryGirl.create(:version, project: project)

        copy.send(:copy_versions, project)
        copy.save
      end

      subject { copy.versions.count }

      it { should == project.versions.count }
    end

    describe :copy_project_associations do
      let(:project2) { FactoryGirl.create(:project_with_types) }

      describe :project_a_associations do
        before do
          FactoryGirl.create(:project_association, project_a: project, project_b: project2)

          copy.send(:copy_project_associations, project)
          copy.save
        end

        subject { copy.send(:project_a_associations).count }

        it { should == project.send(:project_a_associations).count }
      end

      describe :project_b_associations do
        before do
          FactoryGirl.create(:project_association, project_a: project2, project_b: project)

          copy.send(:copy_project_associations, project)
          copy.save
        end

        subject { copy.send(:project_b_associations).count }

        it { should == project.send(:project_b_associations).count }
      end
    end

    describe :copy_categories do
      before do
        FactoryGirl.create(:category, project: project)

        copy.send(:copy_categories, project)
        copy.save
      end

      subject { copy.categories.count }

      it { should == project.categories.count }
    end
  end
end