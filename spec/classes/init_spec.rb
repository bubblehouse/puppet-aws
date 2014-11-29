require 'spec_helper'
describe 'aws' do

  context 'with defaults for all parameters' do
    it { should contain_class('aws') }
  end
end
