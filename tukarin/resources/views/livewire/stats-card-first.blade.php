<?php

use function Livewire\Volt\{state};

//

?>

<div class="grid grid-cols-2 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
    <div class="rounded-lg bg-zinc-100 dark:bg-zinc-700 border-2 border-accent h-fit py-4 md:py-6">
        <div class="size-full flex justify-around items-top gap-4">
            <div class="flex items-center gap-4">
                <flux:icon.trash class="text-accent-content hidden md:block" />
                <div>
                    <flux:heading class="text-xs md:text-sm">Jumlah Sampah</flux:heading>
                    <flux:heading class="text-lg md:text-xl">1000 kg</flux:heading>
                </div>
            </div>
            <flux:icon.circle-arrow-out-up-right variant="micro" class="text-accent-content" />
        </div>
    </div>
    <div class="rounded-lg bg-zinc-100 dark:bg-zinc-700 border-2 border-accent h-fit py-4 md:py-6">
        <div class="size-full flex justify-around items-top gap-4">
            <div class="flex items-center gap-4">
                <flux:icon.circle-dollar-sign class="text-accent-content hidden md:block" />
                <div>
                    <flux:heading class="text-xs md:text-sm">Jumlah Point</flux:heading>
                    <flux:heading class="text-lg md:text-xl">120 pt</flux:heading>
                </div>
            </div>
            <flux:icon.circle-arrow-out-up-right variant="micro" class="text-accent-content" />
        </div>
    </div>
    <div class="rounded-lg bg-zinc-100 dark:bg-zinc-700 border-2 border-accent h-fit py-4 md:py-6">
        <div class="size-full flex justify-around items-top gap-4">
            <div class="flex items-center gap-4">
                <flux:icon.bike class="text-accent-content hidden md:block" />
                <div>
                    <flux:heading class="text-xs md:text-sm">Jumlah Kurir</flux:heading>
                    <flux:heading class="text-lg md:text-xl">50</flux:heading>
                </div>
            </div>
            <flux:icon.circle-arrow-out-up-right variant="micro" class="text-accent-content" />
        </div>
    </div>
    <div class="rounded-lg bg-zinc-100 dark:bg-zinc-700 border-2 border-accent h-fit py-4 md:py-6">
        <div class="size-full flex justify-around items-top gap-4">
            <div class="flex items-center gap-4">
                <flux:icon.users class="text-accent-content hidden md:block" />
                <div>
                    <flux:heading class="text-xs md:text-sm">Jumlah Nasabah</flux:heading>
                    <flux:heading class="text-lg md:text-xl">100</flux:heading>
                </div>
            </div>
            <flux:icon.circle-arrow-out-up-right variant="micro" class="text-accent-content" />
        </div>
    </div>
</div>