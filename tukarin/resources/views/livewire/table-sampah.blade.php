<?php

use function Livewire\Volt\{state};

//

?>

<div class="w-full h-auto rounded-lg bg-zinc-100 dark:bg-zinc-700 p-4 md:p-6 mb-4">
    <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-x-4 gap-y-2 mb-4">
        <div>
            <flux:heading size="lg">Tabel Jenis Sampah</flux:heading>
            <flux:text>Daftar (Jenis Sampah) beserta informasi detail</flux:text>
        </div>
        <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-x-4 gap-y-2">
            <flux:input icon="magnifying-glass" placeholder="Search..." class="max-w-xs" size="sm" />
            <flux:button icon="cloud-download" size="sm">Export</flux:button>
        </div>
    </div>
</div>