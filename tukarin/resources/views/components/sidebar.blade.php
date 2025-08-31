<div class="min-h-screen bg-white dark:bg-zinc-800">
    <flux:sidebar sticky stashable
        class="bg-zinc-50 dark:bg-zinc-900 border-r rtl:border-r-0 rtl:border-l border-zinc-200 dark:border-zinc-700">
        <flux:sidebar.toggle class="lg:hidden" icon="x-mark" />
        <flux:brand href="#" logo="{{ asset('images/logo.svg') }}" name="Tukar.In" class="px-2" />
        <flux:separator />
        <flux:text class="text-xs">MENU</flux:text>
                <flux:navlist variant="outline">
            <flux:navlist.item icon="layout-dashboard" href="{{ route('admin.dashboard') }}" :current="request()->routeIs('admin.dashboard')">Beranda</flux:navlist.item>
            <flux:navlist.item icon="recycle" href="{{ route('admin.sampah-point') }}" :current="request()->routeIs('admin.sampah-point')">Sampah & Point</flux:navlist.item>
            <flux:navlist.group expandable heading="Transaksi" class="hidden lg:grid">
                <flux:navlist.item href="{{ route('admin.transaksi-langsung') }}" :current="request()->routeIs('admin.transaksi-langsung')">Langsung</flux:navlist.item>
                <flux:navlist.item href="{{ route('admin.transaksi-jemput') }}" :current="request()->routeIs('admin.transaksi-jemput')">Dijemput</flux:navlist.item>
            </flux:navlist.group>
            <flux:navlist.item icon="bike" href="#">Data Kurir</flux:navlist.item>
            <flux:navlist.item icon="file-spreadsheet" href="#">Laporan</flux:navlist.item>
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