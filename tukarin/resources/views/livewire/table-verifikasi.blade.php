<?php

use function Livewire\Volt\{state};

//

?>

<div class="w-full h-auto rounded-lg bg-zinc-100 dark:bg-zinc-700 p-4 md:p-6 mb-4">
    <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-x-4 gap-y-2 mb-4">
        <div>
            <flux:heading size="lg">Tabel Verifikasi</flux:heading>
            <flux:text>Daftar (Verifikasi) beserta informasi detail</flux:text>
        </div>
        <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-x-4 gap-y-2">
            <flux:input icon="magnifying-glass" placeholder="Search..." class="max-w-xs" size="sm" />
            <livewire:button-export />
            <flux:modal.trigger name="delete-profile">
                <flux:button icon="trash" size="sm">Hapus</flux:button>
            </flux:modal.trigger>
        </div>
    </div>
    <livewire:modal-delete />
    {{-- table --}}
    <flux:table>
        <flux:table.columns>
            <flux:table.column></flux:table.column>
            <flux:table.column>Nama Bank Sampah</flux:table.column>
            <flux:table.column>Pihak Pengolah</flux:table.column>
            <flux:table.column>Total Berat</flux:table.column>
            <flux:table.column>Bukti Dokumen</flux:table.column>
            <flux:table.column>Status</flux:table.column>
            <flux:table.column></flux:table.column>
        </flux:table.columns>
        <flux:table.rows>
            <flux:table.row>
                <flux:table.cell>
                    <flux:checkbox wire:model="check" />
                </flux:table.cell>
                <flux:table.cell>
                    BS Resik Becik
                </flux:table.cell>
                <flux:table.cell>
                    Agus Profile
                </flux:table.cell>
                <flux:table.cell>
                    10000Kg
                </flux:table.cell>
                <flux:table.cell>
                    <flux:link href="#">laporan_05/09/2005.pdf</flux:link>
                </flux:table.cell>
                <flux:table.cell>
                    <flux:badge variant="pill" icon="circle-small" color="yellow" size="sm">Diproses</flux:badge>
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