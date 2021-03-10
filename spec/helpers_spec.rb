require 'spec_helper'

require './lib/helpers'

describe 'Helpers' do

  context 'seconds_to_human' do
    it 'works with 0 seconds' do
      expect(seconds_to_human(0)).to eq('--m--s')
    end

    it 'works with 1254 seconds' do
      expect(seconds_to_human(1254)).to eq('20m54s')
    end

    it 'works with 4501 seconds' do
      expect(seconds_to_human(4501)).to eq(' 1h15m')
    end

    it 'works with 90000 seconds' do
      expect(seconds_to_human(90000)).to eq(' 1d 1h')
    end

    it 'works with 2073600 seconds' do
      expect(seconds_to_human(2073600)).to eq('   24d')
    end
  end

  context 'asciiThreadLoad' do
    it 'works when empty' do
      expect(asciiThreadLoad(0, 0, 0)).to eq('0[]0')
    end

    it 'works with data' do
      expect(asciiThreadLoad(4, 8, 8)).to eq('4[████░░░░]8')
    end

    it 'show spawned threads' do
      expect(asciiThreadLoad(4, 6, 8)).to eq('4[████░░  ]8')
    end

    it 'works when full' do
      expect(asciiThreadLoad(9, 9, 9)).to eq('9[█████████]9')
    end
  end

  context 'color' do
    it 'colors in red when critical' do
      expect(color(75, 50, 80, "critical")).to eq("\e[0;31;49mcritical\e[0m")
    end

    it 'colors in yellow when warning' do
      expect(color(75, 50, 60, "warn")).to eq("\e[0;33;49mwarn\e[0m")
    end

    it 'colors in green when ok' do
      expect(color(75, 50, 20, "ok")).to eq("\e[0;32;49mok\e[0m")
    end

    it 'works with non string' do
      expect(color(75, 50, 0.52, 0.52)).to eq("\e[0;32;49m0.52\e[0m")
    end
  end


end
