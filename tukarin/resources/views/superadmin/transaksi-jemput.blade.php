<x-layouts.app>
  <x-sidebar>
    <div class="flex flex-col md:flex-row items-start md:items-center justify-start mb-2 gap-2">
      <flux:heading size="xl" level="1">Transaksi</flux:heading>
      <flux:icon.chevron-right />
      <flux:heading size="xl" level="1" class="text-zinc-400">Jemput</flux:heading>
    </div>
    <flux:separator class="mb-2" />
    <livewire:table-transaksi-jemput />
  </x-sidebar>
</x-layouts.app>