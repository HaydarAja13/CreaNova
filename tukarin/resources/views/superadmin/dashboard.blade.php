<x-layouts.app>
  <x-sidebar>
    <div class="flex flex-col md:flex-row items-start md:items-center justify-between mb-2 gap-2">
      <flux:heading size="xl" level="1">Dashboard</flux:heading>
      <div class="flex gap-4 items-center justify-center">
        <flux:dropdown>
          <flux:button icon="list-filter" size="sm">Filter</flux:button>
          <flux:menu>
            <flux:menu.radio.group wire:model="sortBy">
              <flux:menu.radio checked>Mingguan</flux:menu.radio>
              <flux:menu.radio>Bulanan</flux:menu.radio>
              <flux:menu.radio>Tahunan</flux:menu.radio>
            </flux:menu.radio.group>
          </flux:menu>
        </flux:dropdown>
        <flux:button icon="cloud-download" size="sm">Export</flux:button>
      </div>
    </div>
    <flux:separator class="mb-2" />
    <livewire:stats-card-first />
    <livewire:stats-card-second />
    <livewire:stats-card-third />
  </x-sidebar>
</x-layouts.app>