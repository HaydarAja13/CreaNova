<?php

use function Livewire\Volt\{state};

// Chart 1: Sampah Masuk
state(['seriesLangsung' => [30, 40, 45, 50, 49, 60, 70, 91, 125]]);
state(['seriesDijemput' => [10, 25, 20, 12, 35, 158, 165, 80, 110]]);
state(['categoriesData' => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep']]);

// Chart 2: Kategori Sampah
state(['barChartSeries' => [400, 430, 448, 470, 540, 580, 690]]);
state(['barChartCategories' => ['Kertas', 'Besi', 'Kardus', 'Botol', 'Kaca', 'Elektronik', 'Makanan']]);

?>

<div class="grid grid-cols-1 sm:grid-cols-1 lg:grid-cols-2 gap-4 mb-4">
    <div class="rounded-lg bg-zinc-100 dark:bg-zinc-700 min-h-64 md:h-72 p-4 md:p-6">
        <flux:heading size="lg">Sampah Masuk</flux:heading>
        <div class="min-h-full md:pb-4">
            <div id="chart-sampah-masuk"></div>
        </div>
    </div>
    <div class="rounded-lg bg-zinc-100 dark:bg-zinc-700 min-h-64 md:h-72 p-4 md:p-6">
        <flux:heading size="lg">Kategori Sampah</flux:heading>
        <div class="min-h-full md:pb-4">
            <div id="chart-kategori-sampah"></div>
        </div>
    </div>
</div>

@script
<script>
    document.addEventListener('livewire:navigated', () => {
        setTimeout(() => {
            if (window.themeObserverSecond) {
                window.themeObserverSecond.disconnect();
            }

            if (window.areaChart) {
                window.areaChart.destroy();
            }
            if (window.barChart) {
                window.barChart.destroy();
            }

            const getTheme = () => document.documentElement.classList.contains('dark') ? 'dark' : 'light';

            const getForeColor = () => {
                return document.documentElement.classList.contains('dark') ? '#f9fafb' : '#111827';
            }

            const chartElSampahMasuk = document.querySelector("#chart-sampah-masuk");
            if (chartElSampahMasuk) {
                // Chart 1: Sampah Masuk (Area)
                const areaOptions = {
                    chart: {
                        type: 'area',
                        height: '100%',
                        toolbar: { show: false },
                        background: 'transparent',
                        foreColor: getForeColor()
                    },
                    theme: {
                        mode: getTheme()
                    },
                    series: [
                        {
                            name: 'Langsung',
                            data: @json($seriesLangsung)
                        },
                        {
                            name: 'Dijemput',
                            data: @json($seriesDijemput)
                        }
                    ],
                    xaxis: {
                        categories: @json($categoriesData)
                    },
                    colors: ['#3E7B27', '#F5C45E'],
                    dataLabels: { enabled: false },
                    stroke: { curve: 'smooth' },
                    fill: {
                        type: 'gradient',
                        gradient: { shadeIntensity: 1, opacityFrom: 0.7, opacityTo: 0.9, stops: [0, 90, 100] }
                    },
                    legend: {
                        position: 'bottom',
                        horizontalAlign: 'center'
                    },
                    tooltip: {
                        y: { formatter: (val) => val + " kg" }
                    }
                };
                window.areaChart = new ApexCharts(chartElSampahMasuk, areaOptions);
                window.areaChart.render();
            }

            const chartElKategoriSampah = document.querySelector("#chart-kategori-sampah");
            if (chartElKategoriSampah) {
                // Chart 2: Kategori Sampah (Bar)
                const barOptions = {
                    chart: {
                        type: 'bar',
                        height: '100%',
                        toolbar: { show: false },
                        background: 'transparent',
                        foreColor: getForeColor()
                    },
                    theme: {
                        mode: getTheme()
                    },
                    series: [{
                        name: 'Jumlah',
                        data: @json($barChartSeries)
                    }],
                    xaxis: {
                        categories: @json($barChartCategories)
                    },
                    colors: ['#3E7B27'],
                    plotOptions: {
                        bar: {
                            horizontal: false,
                        }
                    },
                    tooltip: {
                        x: { formatter: (val) => val + " kg" }
                    }
                };
                window.barChart = new ApexCharts(chartElKategoriSampah, barOptions);
                window.barChart.render();
            }

            // Observer for theme changes
            if (window.areaChart && window.barChart) {
                window.themeObserverSecond = new MutationObserver((mutations) => {
                    mutations.forEach((mutation) => {
                        if (mutation.attributeName === 'class') {
                            const newTheme = getTheme();
                            const newForeColor = getForeColor();

                            window.areaChart.updateOptions({
                                theme: { mode: newTheme },
                                chart: { foreColor: newForeColor }
                            });
                            window.barChart.updateOptions({
                                theme: { mode: newTheme },
                                chart: { foreColor: newForeColor }
                            });
                        }
                    });
                });

                window.themeObserverSecond.observe(document.documentElement, { attributes: true });
            }
        }, 0);
    });

    window.addEventListener('livewire:navigating', () => {
        if (window.areaChart) {
            window.areaChart.destroy();
            window.areaChart = null;
        }
        if (window.barChart) {
            window.barChart.destroy();
            window.barChart = null;
        }
        if (window.themeObserverSecond) {
            window.themeObserverSecond.disconnect();
            window.themeObserverSecond = null;
        }
    });

</script>
@endscript