<?php

use function Livewire\Volt\{state};

//

?>

<div class="w-full h-auto rounded-lg bg-zinc-100 dark:bg-zinc-700 p-4 md:p-6 mb-4">
    <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-x-4 gap-y-2 mb-4">
        <div>
            <flux:heading size="lg">Tabel Bank Sampah</flux:heading>
            <flux:text>Daftar (Bank Sampah) beserta informasi detail</flux:text>
        </div>
        <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-x-4 gap-y-2">
            <flux:input icon="magnifying-glass" placeholder="Search..." class="max-w-xs" size="sm" />
            <livewire:button-export />
            <flux:modal.trigger name="delete-profile">
                <flux:button icon="trash" size="sm">Hapus</flux:button>
            </flux:modal.trigger>
            <flux:button icon="plus" class="bg-accent" variant="primary" size="sm">Tambah</flux:button>
        </div>
    </div>
    <livewire:modal-delete />
    {{-- table --}}
    <flux:table>
        <flux:table.columns>
            <flux:table.column></flux:table.column>
            <flux:table.column>ID Bank Sampah</flux:table.column>
            <flux:table.column>Nama Bank Sampah</flux:table.column>
            <flux:table.column>Alamat</flux:table.column>
            <flux:table.column>Email</flux:table.column>
            <flux:table.column>Stok Sampah</flux:table.column>
            <flux:table.column>Distribusi Poin </flux:table.column>
            <flux:table.column>Status </flux:table.column>
            <flux:table.column></flux:table.column>
        </flux:table.columns>
        <flux:table.rows>
            <flux:table.row>
                <flux:table.cell>
                    <flux:checkbox wire:model="check" />
                </flux:table.cell>
                <flux:table.cell variant="strong">
                    BS-0101
                </flux:table.cell>
                <flux:table.cell>
                    Bank Sampah Resik Becik
                </flux:table.cell>
                <flux:table.cell>
                    <flux:text class="truncate w-48">Jl. Melati No. 45, Surabaya</flux:text>
                </flux:table.cell>
                <flux:table.cell>
                    resikbecik@gmail.com
                </flux:table.cell>
                <flux:table.cell>
                    10000Kg
                </flux:table.cell>
                <flux:table.cell>
                    2000P
                </flux:table.cell>
                <flux:table.cell>
                    <flux:badge variant="pill" icon="circle-small" color="green" size="sm">Aktif </flux:badge>
                </flux:table.cell>
                <flux:table.cell>
                    <flux:dropdown position="bottom" align="end" offset="-15">
                        <flux:button variant="ghost" size="sm" icon="ellipsis-vertical" inset="top bottom">
                        </flux:button>
                        <flux:menu>
                            <flux:menu.item icon="eye">Detail</flux:menu.item>
                            <flux:menu.item icon="pencil-square">Edit</flux:menu.item>
                            <flux:menu.item icon="trash">Hapus</flux:menu.item>
                        </flux:menu>
                    </flux:dropdown>
                </flux:table.cell>
            </flux:table.row>
        </flux:table.rows>
    </flux:table>
</div>