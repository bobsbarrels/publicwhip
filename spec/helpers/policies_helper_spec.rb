require 'spec_helper'

describe PoliciesHelper, type: :helper do
  describe ".policies_list_sentence" do
    let(:user) { User.create!(email: "matthew@oaf.org.au", password: "foofoofoo", name: 'Matthew Landauer') }
    let(:policy1) { Policy.create!(id: 1, name: "A nice policy", description: "nice", user: user, private: 0) }
    let(:policy2) { Policy.create!(id: 2, name: "A provisional policy", description: "prov", user: user, private: 2) }
    let(:policy3) { Policy.create!(id: 3, name: "<em>A</em> provisional policy", description: "prov", user: user, private: 2) }

    it { expect(helper.policies_list_sentence([policy1])).to eq '<a href="/policies/1">A nice policy</a>' }
    it { expect(helper.policies_list_sentence([policy2])).to eq '<a href="/policies/2">A provisional policy</a> <i>(draft)</i>'}
    it { expect(helper.policies_list_sentence([policy3])).to eq '<a href="/policies/3">&lt;em&gt;A&lt;/em&gt; provisional policy</a> <i>(draft)</i>'}
    it { expect(helper.policies_list_sentence([policy3])).to be_html_safe }
    it { expect(helper.policies_list_sentence([policy1, policy2])).to eq '<a href="/policies/1">A nice policy</a> and <a href="/policies/2">A provisional policy</a> <i>(draft)</i>'}
  end

  describe ".version_sentence" do
    before :each do
      allow(Policy).to receive(:find).with(3).and_return(mock_model(Policy, id: 3, name: "chickens"))
    end

    context "create provisional policy" do
      let(:version) { double("version", item_type: "Policy", event: "create", changeset: {"name" => [nil, "A new policy"], "description" => [nil, "Oh yes!"], "private" => [nil, 2], "id" => [nil, 3]}) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Created draft policy “A new policy” with description “Oh yes!”.</p>' }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "create policy" do
      let(:version) { double("version", item_type: "Policy", event: "create", changeset: {"name" => [nil, "A new policy"], "description" => [nil, "Oh yes!"], "private" => [nil, 0], "id" => [nil, 3]}) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Created policy “A new policy” with description “Oh yes!”.</p>' }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "change name on policy" do
      let(:version) { double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"name" => ["Version A", "Version B"]}, reify: mock_model(Policy, id: 3, name: "Version A")) }
      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Name changed from “Version A” to “Version B”.</p>' }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "change description on policy" do
      let(:version) { double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"description" => ["Description A", "Description B"]}, reify: mock_model(Policy, id: 3, name: "Version A")) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Description changed from “Description A” to “Description B”.</p>' }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "change status on policy" do
      let(:version) { double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"private" => [2, 0]}, reify: mock_model(Policy, id: 3, name: "Version A")) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Changed status to not draft.</p>' }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "change everything on policy" do
      let(:version) { double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"name" => ["Version A", "Version B"], "description" => ["Description A", "Description B"], "private" => [0, 2]}, reify: mock_model(Policy, id: 3, name: "Version A")) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Name changed from “Version A” to “Version B”.</p><p class="change-action">Description changed from “Description A” to “Description B”.</p><p class="change-action">Changed status to draft.</p>' }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "changing policy vote" do
      before :each do
        expect(Division).to receive(:find).with(5).and_return(mock_model(Division, name: "blah", date: Date.new(2001,1,1), number: 2, house: "representatives"))
      end

      context "create vote on policy" do
        let(:version) { double("version", item_type: "PolicyDivision", event: "create", whodunnit: 1, created_at: 1.hour.ago, changeset: {"vote" => [nil, "aye3"], "division_id" => [nil, 5]}, policy_id: 3) }

        it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Added division <em><a href="/divisions/representatives/2001-01-01/2">blah</a></em>. Policy vote set to <span class="division-policy-statement-vote voted-aye">Yes (strong)</span>.</p>' }
        it { expect(helper.version_sentence(version)).to be_html_safe }
      end

      context "remove vote on policy" do
        let(:version) { double("version", item_type: "PolicyDivision", event: "destroy", whodunnit: 1, created_at: 1.hour.ago, changeset: nil, reify: double("policy_division", division_id: 5, vote: "no"), policy_id: 3) }

        it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Removed division <em><a href="/divisions/representatives/2001-01-01/2">blah</a></em>. Policy vote was <span class="division-policy-statement-vote voted-no">No</span>.</p>' }
        it { expect(helper.version_sentence(version)).to be_html_safe }
      end

      context "change vote on policy" do
        let(:version) { double("version", item_type: "PolicyDivision", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"vote" => ["no", "aye"]}, reify: double("policy_division", division_id: 5), policy_id: 3) }

        it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Changed vote from <span class="division-policy-statement-vote voted-no">No</span> to <span class="division-policy-statement-vote voted-aye">Yes</span> on division <em><a href="/divisions/representatives/2001-01-01/2">blah</a></em>.</p>' }
        it { expect(helper.version_sentence(version)).to be_html_safe }
      end
    end
  end
end
