<?php

use function Livewire\Volt\{state};

state(['chartNasabah' => 75]);

?>

<div class="grid grid-cols-1 gap-4 sm:grid-cols-1 lg:grid-cols-3">
    <div class="h-56 rounded-lg bg-zinc-100 p-4 md:h-auto md:p-6 lg:col-span-2 dark:bg-zinc-700">
        <div class="flex items-center justify-between">
            <flux:heading size="lg">Aktifitas Kurir Terbaru</flux:heading>
            <flux:button href="https://google.com" icon:trailing="arrow-up-right" size="sm">
                Detail
            </flux:button>
        </div>
    </div>
    <div class="rounded-lg bg-zinc-100 p-4 h-auto md:p-6 dark:bg-zinc-700 flex flex-col items-center justify-center">
        <flux:heading size="lg">Pelanggan</flux:heading>
        <div id="chart-nasabah-aktif"></div>
        <flux:badge icon="user-circle" color="yellow" variant="pill">Nasabah Aktif</flux:badge>
    </div>
</div>

@script
<script>
    document.addEventListener('livewire:navigated', () => {
        if (window.themeObserver) {
            window.themeObserver.disconnect();
        }

        const getTheme = () => document.documentElement.classList.contains('dark') ? 'dark' : 'light';

        const getLabelColors = () => {
            return document.documentElement.classList.contains('dark')
                ? { valueColor: '#f9fafb' } 
                : { valueColor: '#111827' };
        }

        const radialOptions = {
            chart: {
                height: "auto",
                type: "radialBar",
                background: 'transparent'
            },
            grid: {
                padding: {
                    top: -20,
                    right: 0,
                    bottom: 0,
                    left: 0
                }
            },
            theme: {
                mode: getTheme()
            },
            series: [@json($chartNasabah)],
            colors: ["#F5C45E"],
            plotOptions: {
                radialBar: {
                    inverse: false,
                    startAngle: -135,
                    endAngle: 135,
                    hollow: {
                        margin: 0,
                        size: '60%',
                        background: 'transparent',
                        image: '{{ asset("images/user.svg") }}',
                        imageWidth: 56,
                        imageHeight: 56,
                        imageClipped: false,
                    },
                    track: {
                        background: '#777777',
                        startAngle: -135,
                        endAngle: 135,
                    },
                    dataLabels: {
                        name: {
                            show: false,
                        },
                        value: {
                            show: true,
                            fontSize: "20",
                            color: getLabelColors().valueColor,
                            offsetY: 50,
                            formatter: function (val) {
                            return val;
                            }
                        }
                    }
                }
            },
            fill: {
                type: "fill",
            },
            stroke: {
                lineCap: "round"
            },
            labels: false
        };
        const radialChart = new ApexCharts(document.querySelector("#chart-nasabah-aktif"), radialOptions);
        radialChart.render();

        window.themeObserver = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.attributeName === 'class') {
                    const newTheme = getTheme();
                    const newLabelColors = getLabelColors();
                    radialChart.updateOptions({
                        theme: {
                            mode: newTheme
                        },
                        plotOptions: {
                            radialBar: {
                                dataLabels: {
                                    value: {
                                        color: newLabelColors.valueColor
                                    }
                                }
                            }
                        }
                    });
                }
            });
        });

        window.themeObserver.observe(document.documentElement, {
            attributes: true
        });
    });
</script>
@endscript