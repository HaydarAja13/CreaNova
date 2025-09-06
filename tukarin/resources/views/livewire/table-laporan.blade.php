<?php

use function Livewire\Volt\{state};

//

?>

<div class="w-full h-auto rounded-lg bg-zinc-100 dark:bg-zinc-700 p-4 md:p-6 mb-4">
    <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-x-4 gap-y-2 mb-4">
        <div>
            <flux:heading size="lg">Tabel Laporan</flux:heading>
            <flux:text>Daftar (Laporan) beserta informasi detail</flux:text>
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
            <flux:table.column>ID Laporan</flux:table.column>
            <flux:table.column>Judul Laporan</flux:table.column>
            <flux:table.column>Tanggal Dibuat</flux:table.column>
            <flux:table.column>Periode</flux:table.column>
            <flux:table.column>Status</flux:table.column>
            <flux:table.column></flux:table.column>
        </flux:table.columns>
        <flux:table.rows>
            <flux:table.row>
                <flux:table.cell>
                    <flux:checkbox wire:model="check" />
                </flux:table.cell>
                <flux:table.cell variant="strong">
                    LBS-0101
                </flux:table.cell>
                <flux:table.cell>
                    <flux:text class="truncate w-48">Laporan Bank Sampah Resik Becik</flux:text>
                </flux:table.cell>
                <flux:table.cell>
                    03 September 2025
                </flux:table.cell>
                <flux:table.cell>
                    2024 / 2025
                </flux:table.cell>
                <flux:table.cell>
                    <flux:badge variant="pill" icon="circle-small" color="green" size="sm">Diverifikasi</flux:badge>
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