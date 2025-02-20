# frozen_string_literal: true

require "spec_helper"

describe DivisionsController, type: :request do
  include HTMLCompareHelper
  fixtures :all

  describe "#show" do
    it { compare_static("/divisions/representatives/2006-12-06/3") }
    it { compare_static("/divisions/representatives/2013-03-14/1") }
    it { compare_static("/divisions/senate/2013-03-14/1") }

    it { compare_static("/divisions/representatives/2006-12-06/3/policies", signed_in: true) }
    it { compare_static("/divisions/representatives/2013-03-14/1/policies", signed_in: true) }
    it { compare_static("/divisions/representatives/2013-03-14/1/policies", suffix: "_2") }
    it { compare_static("/divisions/senate/2009-11-25/8/policies", signed_in: true) }
    it { compare_static("/divisions/senate/2009-11-25/8/policies/1", signed_in: true) }
    it { compare_static("/divisions/senate/2009-11-25/8/policies/2", signed_in: true) }
    it { compare_static("/divisions/senate/2013-03-14/1/policies", signed_in: true) }
    it { compare_static("/divisions/senate/2013-03-14/1/policies", suffix: "_2") }
  end

  describe "#index" do
    it { compare_static("/divisions") }
    it { compare_static("/divisions/all/2007") }
    it { compare_static("/divisions/all/2004") }
    it { compare_static("/divisions/all") }
    it { compare_static("/divisions/representatives") }
    it { compare_static("/divisions/representatives/2007") }
    it { compare_static("/divisions/representatives/2004") }
    it { compare_static("/divisions/senate") }
    it { compare_static("/divisions/senate/2007") }
    it { compare_static("/divisions/senate/2004") }

    it { compare_static("/divisions?sort=subject") }
    it { compare_static("/divisions/all/2007?sort=subject") }
    it { compare_static("/divisions/all/2004?sort=subject") }
    it { compare_static("/divisions/all?sort=subject") }
    it { compare_static("/divisions/representatives?sort=subject") }
    it { compare_static("/divisions/representatives/2007?sort=subject") }
    it { compare_static("/divisions/representatives/2004?sort=subject") }
    it { compare_static("/divisions/senate?sort=subject") }
    it { compare_static("/divisions/senate/2007?sort=subject") }
    it { compare_static("/divisions/senate/2004?sort=subject") }

    it { compare_static("/divisions?sort=rebellions") }
    it { compare_static("/divisions/all/2007?sort=rebellions") }
    it { compare_static("/divisions/all/2004?sort=rebellions") }
    it { compare_static("/divisions/all?sort=rebellions") }
    it { compare_static("/divisions/representatives?sort=rebellions") }
    it { compare_static("/divisions/representatives/2007?sort=rebellions") }
    it { compare_static("/divisions/representatives/2004?sort=rebellions") }
    it { compare_static("/divisions/senate?sort=rebellions") }
    it { compare_static("/divisions/senate/2007?sort=rebellions") }
    it { compare_static("/divisions/senate/2004?sort=rebellions") }

    it { compare_static("/divisions?sort=turnout") }
    it { compare_static("/divisions/all/2007?sort=turnout") }
    it { compare_static("/divisions/all/2004?sort=turnout") }
    it { compare_static("/divisions/all?sort=turnout") }
    it { compare_static("/divisions/representatives?sort=turnout") }
    it { compare_static("/divisions/representatives/2007?sort=turnout") }
    it { compare_static("/divisions/representatives/2004?sort=turnout") }
    it { compare_static("/divisions/senate?sort=turnout") }
    it { compare_static("/divisions/senate/2007?sort=turnout") }
    it { compare_static("/divisions/senate/2004?sort=turnout") }
  end

  describe "#edit" do
    it { compare_static "/divisions/senate/2009-11-25/8/edit", signed_in: true }
    it { compare_static "/divisions/representatives/2013-03-14/1/edit", signed_in: true }
  end

  describe "#update" do
    it { compare_static "/divisions/senate/2009-11-25/8", signed_in: true, form_params: { submit: "Save", newtitle: "A lovely new title", newdescription: "And a great new description" } }
  end
end
