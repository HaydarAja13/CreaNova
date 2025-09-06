<div class="min-h-screen bg-white dark:bg-zinc-800">
    <flux:sidebar sticky stashable
        class="bg-zinc-50 dark:bg-zinc-900 border-r rtl:border-r-0 rtl:border-l border-zinc-200 dark:border-zinc-700">
        <flux:sidebar.toggle class="lg:hidden" icon="x-mark" />
        <flux:brand href="#" logo="{{ asset('images/logo.svg') }}" name="Tukar.In" class="px-2" />
        <flux:separator />
        <flux:text class="text-xs">MENU</flux:text>
        <flux:navlist variant="outline">
            @if (request()->is('admin*'))
            <flux:navlist.item icon="layout-dashboard" href="{{ route('admin.dashboard') }}"
                :current="request()->routeIs('admin.dashboard')" wire:navigate>Beranda</flux:navlist.item>
            <flux:navlist.item icon="recycle" href="{{ route('admin.sampah-point') }}"
                :current="request()->routeIs('admin.sampah-point')" wire:navigate>Sampah & Poin</flux:navlist.item>
            <flux:navlist.group expandable heading="Transaksi">
                <flux:navlist.item href="{{ route('admin.transaksi-langsung') }}"
                    :current="request()->routeIs('admin.transaksi-langsung')" wire:navigate>Langsung</flux:navlist.item>
                <flux:navlist.item href="{{ route('admin.transaksi-jemput') }}"
                    :current="request()->routeIs('admin.transaksi-jemput')" wire:navigate>Dijemput</flux:navlist.item>
            </flux:navlist.group>
            <flux:navlist.item icon="bike" href="{{ route('admin.kurir') }}"
                :current="request()->routeIs('admin.kurir')" wire:navigate>Data Kurir</flux:navlist.item>
            <flux:navlist.item icon="file-spreadsheet" href="{{ route('admin.laporan') }}"
                :current="request()->routeIs('admin.laporan')" wire:navigate>Laporan</flux:navlist.item>
            @elseif (request()->is('superadmin*'))
            <flux:navlist.item icon="layout-dashboard" href="{{ route('superadmin.dashboard') }}"
                :current="request()->routeIs('superadmin.dashboard')" wire:navigate>Beranda</flux:navlist.item>
            <flux:navlist.item icon="recycle" href="{{ route('superadmin.sampah-point') }}"
                :current="request()->routeIs('superadmin.sampah-point')" wire:navigate>Sampah & Poin</flux:navlist.item>
            <flux:navlist.item icon="bike" href="{{ route('superadmin.kurir') }}"
                :current="request()->routeIs('superadmin.kurir')" wire:navigate>Data Kurir</flux:navlist.item>
            <flux:navlist.item icon="file-spreadsheet" href="{{ route('superadmin.laporan') }}"
                :current="request()->routeIs('superadmin.laporan')" wire:navigate>Laporan</flux:navlist.item>
            <flux:navlist.item icon="map-pin-house" href="{{ route('superadmin.bank-sampah') }}"
                :current="request()->routeIs('superadmin.bank-sampah')" wire:navigate>Bank Sampah</flux:navlist.item>
            <flux:navlist.item icon="badge-check" href="{{ route('superadmin.verifikasi') }}"
                :current="request()->routeIs('superadmin.verifikasi')" wire:navigate>Verifikasi</flux:navlist.item>
            <flux:navlist.item icon="users" href="{{ route('superadmin.nasabah') }}"
                :current="request()->routeIs('superadmin.nasabah')" wire:navigate>Nasabah</flux:navlist.item>
            <flux:navlist.item icon="book-text" href="{{ route('superadmin.artikel') }}"
                :current="request()->routeIs('superadmin.artikel')" wire:navigate>Artikel</flux:navlist.item>
            <flux:navlist.item icon="ticket-percent" href="{{ route('superadmin.voucher') }}"
                :current="request()->routeIs('superadmin.voucher')" wire:navigate>Voucher</flux:navlist.item>
            @endif
        </flux:navlist>
        <flux:spacer />
        <flux:navlist variant="outline">
            <flux:navlist.item icon="sun-moon" x-data x-on:click="$flux.dark = ! $flux.dark">Tema Aplikasi
            </flux:navlist.item>
            <flux:navlist.item icon="circle-question-mark" href="#">Bantuan</flux:navlist.item>
        </flux:navlist>
        <flux:dropdown position="top" align="start" class="max-lg:hidden">
            <flux:profile avatar="{{ asset('images/profile_1.avif') }}" name="BS Resik Becik" />
            <flux:menu>
                <flux:menu.item icon="arrow-right-start-on-rectangle">Logout</flux:menu.item>
            </flux:menu>
        </flux:dropdown>
    </flux:sidebar>
    <flux:header class="lg:hidden">
        <flux:sidebar.toggle class="lg:hidden" icon="bars-2" inset="left" />
        <flux:spacer />
        <flux:dropdown position="top" alignt="start">
            <flux:profile avatar="{{ asset('images/profile_1.avif') }}" />
            <flux:menu>
                <flux:menu.item icon="arrow-right-start-on-rectangle">Logout</flux:menu.item>
            </flux:menu>
        </flux:dropdown>
    </flux:header>
    <flux:main>
        {{ $slot }}
    </flux:main>
</div>