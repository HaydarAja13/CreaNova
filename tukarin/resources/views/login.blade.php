<x-layouts.app>
<div class="flex min-h-screen overflow-hidden">
    <div class="fixed bottom-6 left-6 z-50">
        <flux:button x-data x-on:click="$flux.dark = ! $flux.dark" icon="moon" variant="subtle" aria-label="Toggle dark mode" />
    </div>
    <div class="flex-1 flex justify-center items-center">
        <div class="w-80 max-w-80 space-y-6">
            <flux:heading class="text-center" size="xl">Login</flux:heading>

            <div class="flex flex-col gap-6">
                <flux:input label="Email" type="email" placeholder="email@example.com" />

                <flux:field>
                    <div class="mb-3 flex justify-between">
                        <flux:label>Password</flux:label>

                        <flux:link href="#" variant="subtle" class="text-sm">Lupa password?</flux:link>
                    </div>

                    <flux:input type="password" placeholder="••••••••" />
                </flux:field>

                <flux:button variant="primary" class="w-full">Log in</flux:button>
            </div>

            <flux:subheading class="text-center">
                Tukarin Demo - Built with
                <flux:icon.heart class="inline text-red-500" /> by <flux:link href="https://fluxui.dev" target="_blank">
                    Flux UI</flux:link>
            </flux:subheading>
        </div>
    </div>

    <div class="flex-1 p-4 max-lg:hidden">
        <div class="text-white relative rounded-lg h-full w-full bg-zinc-900 flex flex-col items-start justify-end p-16"
            style="background-image: url('{{ asset('images/login_image.avif') }}'); background-size: cover; background-position: center; ">
            <div class="dark:bg-black/60 bg-white/60 absolute inset-0 rounded-lg"></div>
            <flux:heading size="xl" class="z-10">Tukar.In</flux:heading>
            <flux:subheading class="z-10">Selamat datang di portal Admin Tukar.In. Silakan masuk untuk mulai
                mengelola operasional, memvalidasi setoran, dan
                melayani proses penukaran sampah dari warga.</flux:subheading>
        </div>
    </div>
</div>
</x-layouts.app>