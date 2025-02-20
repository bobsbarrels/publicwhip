# frozen_string_literal: true

require "spec_helper"
# Compare results of rendering pages via rails and via the old php app

describe PoliciesController, type: :request do
  include HTMLCompareHelper
  fixtures :all

  let(:user) { create(:user, id: 1, name: "Henare Degan") }

  before do
    # To workaround paper trail and fixtures problems we're deleting the static
    # fixtures data and recreating here in such a way that the versions in paper
    # trail are setup the way we want
    Policy.delete_all
    PaperTrail::Version.delete_all
    User.delete_all

    PaperTrail.whodunnit = user.id
    Timecop.freeze(25.hours.ago) do
      create(:policy, id: 1, name: "marriage equality", description: "access to marriage should be equal")
      create(:policy, id: 2, name: "offshore processing", description: "refugees arrving by boat should be processed offshore")
    end
  end

  it "#index" do
    compare_static("/policies")
  end

  describe "#show" do
    it { compare_static("/policies/1") }
    it { compare_static("/policies/2") }
  end
end
