# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'spec_helper'

include Devise::TestHelpers

describe ApplicationHelper do
  describe "#application_version" do
    it("returns the version set on the Mconf object") { application_version.should eq(Mconf::VERSION) }
  end

  describe "#application_revision" do
    before { Mconf.should_receive(:application_revision).and_return('revision') }
    it("returns Mconf.application_revision") { application_revision.should eq('revision') }
  end

  describe "#asset_exists?" do
    it "returns whether an asset file exists"
  end

  describe "#javascript_include_tag_for_controller" do
    it "includes a javascript tag for the current controller"
    it "doesn't include anything if the target javascript doesn't exist"
  end

  describe "#stylesheet_include_tag_for_controller" do
    it "includes a stylesheet tag for the current controller"
    it "doesn't include anything if the target stylesheet doesn't exist"
  end

  describe "#controller_name_for_view" do
    before { params[:controller] = 'devise/sessions' }
    it("returns the current controller name parameterized") {
      controller_name_for_view.should eq('devise-sessions')
    }
  end

  describe "#at_home?" do
    context "true if at MyController#home" do
      before {
        params[:controller] = 'my'
        params[:action] = 'home'
      }
      it { at_home?.should be_truthy }
    end

    context "false if in other action of MyController than #home" do
      before {
        params[:controller] = 'my'
        params[:action] = 'recordings'
      }
      it { at_home?.should be_falsey }
    end

    context "false if in other controller than MyController" do
      before {
        params[:controller] = 'sessions'
        params[:action] = 'home'
      }
      it { at_home?.should be_falsey }
    end
  end

  describe "#webconf_url_prefix" do
    before { Site.current.update_attributes(:domain => 'test.com', :ssl => true) }

    context "returns what is configured in the site" do
      it { webconf_url_prefix.should eq("https://test.com/#{Rails.application.config.conf_scope_rooms}/") }
    end

    context "doesn't return duplicated / when conf_scope_rooms=nil" do
      before {
        @previous = Rails.application.config.conf_scope_rooms
        Rails.application.config.conf_scope_rooms = nil
        Helpers.reload_routes!
      }
      after {
        Rails.application.config.conf_scope_rooms = @previous
        Rails.application.reload_routes!
      }
      it { webconf_url_prefix.should eq("https://test.com/") }
    end
  end

  describe "#webconf_path_prefix" do
    context "returns the path prefix for web conference urls" do
      it { webconf_path_prefix.should eq(Rails.application.config.conf_scope_rooms + '/') }
    end
  end

  describe "#options_for_tooltip" do
    context "returns a hash with the default attributes for tooltips" do
      subject { options_for_tooltip('my-title') }
      it { subject.should be_a(Hash) }
      it('adds a title') { subject.should have_key(:title) }
      it('adds the title specified') { subject[:title].should eq('my-title') }
      it('adds classes') { subject.should have_key(:class) }
      it('adds the class tooltipped') { subject[:class].split(' ').should include('tooltipped') }
      it('adds data-placement') { subject.should have_key(:'data-placement') }
      it('data-placement defaults to top') { subject[:'data-placement'].should eq('top') }
    end

    context "includes the classes passed in the arguments" do
      subject { options_for_tooltip('my-title', { :class => 'first second' }) }
      it('adds the tooltip class') { subject[:class].split(' ').should include('tooltipped') }
      it('adds the base class `first`') { subject[:class].split(' ').should include('first') }
      it('adds the base class `second`') { subject[:class].split(' ').should include('second') }
    end

    context "uses the data-placement passed in the arguments" do
      subject { options_for_tooltip('my-title', { :'data-placement' => 'bottom' }) }
      it('data-placement defaults to top') { subject[:'data-placement'].should eq('bottom') }
    end
  end

  describe "#user_signed_in_via_federation?" do
    context "if signed in in devise and Mconf::Shibboleth" do
      before {
        should_receive(:user_signed_in?).and_return(true)
        Mconf::Shibboleth.any_instance.should_receive(:signed_in?).and_return(true)
      }
      it { user_signed_in_via_federation?.should be_truthy }
    end

    context "if there's no user signed in" do
      before { should_receive(:user_signed_in?).and_return(false) }
      it { user_signed_in_via_federation?.should be_falsey }
    end

    context "if there's a user signed in but not via federation" do
      before {
        should_receive(:user_signed_in?).and_return(true)
        Mconf::Shibboleth.any_instance.should_receive(:signed_in?).and_return(false)
      }
      it { user_signed_in_via_federation?.should be_falsey }
    end
  end

  describe "#user_signed_in_via_ldap?" do
    context "if signed in in devise and Mconf::LDAP" do
      before {
        should_receive(:user_signed_in?).and_return(true)
        Mconf::LDAP.any_instance.should_receive(:signed_in?).and_return(true)
      }
      it { user_signed_in_via_ldap?.should be_truthy }
    end

    context "if there's no user signed in" do
      before { should_receive(:user_signed_in?).and_return(false) }
      it { user_signed_in_via_ldap?.should be_falsey }
    end

    context "if there's a user signed in but not via LDAP" do
      before {
        should_receive(:user_signed_in?).and_return(true)
        Mconf::LDAP.any_instance.should_receive(:signed_in?).and_return(false)
      }
      it { user_signed_in_via_ldap?.should be_falsey }
    end
  end

  describe "#available_locales" do
    before {
      Site.current.update_attributes(visible_locales: [:v1, :v2])
      Rails.application.config.i18n.stub(:available_locales)
        .and_return([:a1, :a2])
    }

    context "when all==false returns only the visible locales" do
      it { available_locales(false).should eq([:v1, :v2]) }
    end

    context "when all==true returns all locales" do
      it { available_locales(true).should eq([:a1, :a2]) }
    end

    context "with no parameters returns only the visible locales" do
      it { available_locales.should eq([:v1, :v2]) }
    end
  end

  describe "#max_upload_size" do
    before {
      allow(helper).to receive(:current_site) { Site.current }
    }

    context "when max_upload_size is set in the site" do
      before {
        Site.current.update_attributes(max_upload_size: "25000000")
      }
      it { helper.max_upload_size.should eq("25000000") }
    end

    context "when max_upload_size is not set in the site" do
      before {
        Site.current.update_attributes(max_upload_size: nil)
      }
      it { helper.max_upload_size.should be_nil }
    end
  end

end
