<x-layouts.app>
  <div class="h-screen flex flex-col items-center justify-center text-center px-4">
    <img src="{{ asset('images/404.svg') }}" alt="" class="w-1/2 max-w-sm mb-6" />
    <flux:heading size="xl" class="mb-4">404</flux:heading>
    <flux:heading size="lg" class="mb-2">Halaman Tidak Ditemukan</flux:heading>
    <flux:text class="mb-6">Maaf, halaman yang Anda cari tidak ada atau telah dipindahkan.</flux:text>
    <flux:button href="{{ url()->previous() }}" icon="arrow-left">
      Kembali ke Tukar.In
    </flux:button>
  </div>
</x-layouts.app>