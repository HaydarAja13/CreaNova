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
        if (window.themeObserverSecond) {
            window.themeObserverSecond.disconnect();
        }

        const getTheme = () => document.documentElement.classList.contains('dark') ? 'dark' : 'light';

        const getForeColor = () => {
            return document.documentElement.classList.contains('dark') ? '#f9fafb' : '#111827';
        }

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
        const areaChart = new ApexCharts(document.querySelector("#chart-sampah-masuk"), areaOptions);
        areaChart.render();

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
        const barChart = new ApexCharts(document.querySelector("#chart-kategori-sampah"), barOptions);
        barChart.render();

        // Observer for theme changes
        window.themeObserverSecond = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.attributeName === 'class') {
                    const newTheme = getTheme();
                    const newForeColor = getForeColor();

                    areaChart.updateOptions({
                        theme: { mode: newTheme },
                        chart: { foreColor: newForeColor }
                    });
                    barChart.updateOptions({
                        theme: { mode: newTheme },
                        chart: { foreColor: newForeColor }
                    });
                }
            });
        });

        window.themeObserverSecond.observe(document.documentElement, { attributes: true });
    });
</script>
@endscript