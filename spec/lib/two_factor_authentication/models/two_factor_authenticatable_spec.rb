require 'spec_helper'
include AuthenticatedModelHelper

describe Devise::Models::TwoFactorAuthenticatable, '#otp_code' do
  let(:instance) { AuthenticatedModelHelper.create_new_user }
  subject { instance.otp_code(time) }
  let(:time) { 1392852456 }
  let(:secret_key) {"2z6hxkdwi3uvrnpn"}
  it "should return an error if no secret is set" do
    expect {
      subject
    }.to raise_error
  end

  context "secret is set" do
    before :each do
      instance.otp_secret_key = "2z6hxkdwi3uvrnpn"
    end

    it "should not return an error" do
      subject
    end

    context "with a known time" do
      let(:time) { 1392852756 }

      it "should return a known result" do
        expect(subject).to eq(562202)
      end
    end
  end
end

describe Devise::Models::TwoFactorAuthenticatable, '#authenticate_otp' do
  let(:instance) { AuthenticatedModelHelper.create_new_user }

  before :each do
    instance.otp_secret_key = "2z6hxkdwi3uvrnpn"
  end

  def do_invoke code, options = {}
    instance.authenticate_otp(code, options)
  end

  it "should be able to authenticate a recently created code" do
    code = instance.otp_code
    expect(do_invoke(code)).to eq(true)
  end

  it "should not authenticate an old code" do
    code = instance.otp_code(1.minutes.ago.to_i)
    expect(do_invoke(code)).to eq(false)
  end
end

describe Devise::Models::TwoFactorAuthenticatable, '#send_two_factor_authentication_code' do

  it "should raise an error by default" do
    instance = AuthenticatedModelHelper.create_new_user
    expect {
      instance.send_two_factor_authentication_code
    }.to raise_error(NotImplementedError)
  end

  it "should be overrideable" do
    instance = AuthenticatedModelHelper.create_new_user_with_overrides
    expect(instance.send_two_factor_authentication_code).to eq("Code sent")
  end
end

describe Devise::Models::TwoFactorAuthenticatable, '#provisioning_uri' do
  let(:instance) { AuthenticatedModelHelper.create_new_user }

  before do
    instance.email = "houdini@example.com"
    instance.run_callbacks :create
  end

  it "should return uri with user's email" do
    expect(instance.provisioning_uri).to match(%r{otpauth://totp/houdini@example.com\?secret=\w{16}})
  end

  it "should return uri with issuer option" do
    expect(instance.provisioning_uri("houdini")).to match(%r{otpauth://totp/houdini\?secret=\w{16}$})
  end

  it "should return uri with issuer option" do
    require 'cgi'

    uri = URI.parse(instance.provisioning_uri("houdini", issuer: 'Magic'))
    params = CGI::parse(uri.query)

    expect(uri.scheme).to eq("otpauth")
    expect(uri.host).to eq("totp")
    expect(uri.path).to eq("/houdini")
    expect(params['issuer'].shift).to eq('Magic')
    expect(params['secret'].shift).to match(%r{\w{16}})
  end

end
