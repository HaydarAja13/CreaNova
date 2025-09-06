<?php

use function Livewire\Volt\{state};

state(['chartNasabah' => 75]);

?>

<div class="grid grid-cols-1 gap-4 sm:grid-cols-1 lg:grid-cols-3">
    <div class="rounded-lg bg-zinc-100 p-4 h-auto md:p-6 lg:col-span-2 dark:bg-zinc-700">
        <div class="flex items-center justify-between mb-2">
            <flux:heading size="lg">Aktifitas Kurir Terbaru</flux:heading>
            <flux:button href="https://google.com" icon:trailing="arrow-up-right" size="sm">
                Detail
            </flux:button>
        </div>
        <flux:table>
            <flux:table.rows>
                <flux:table.row>
                    <flux:table.cell>
                        <flux:avatar circle name="Caleb Porzio" color="auto" />
                    </flux:table.cell>
                    <flux:table.cell>
                        <flux:heading>User profile</flux:heading>
                        <flux:text>This information will be displayed publicly.</flux:text>
                    </flux:table.cell>
                    <flux:table.cell align="end">
                        <flux:badge color="green" size="sm" variant="pill">Online</flux:badge>
                    </flux:table.cell>
                </flux:table.row>

                <flux:table.row>
                    <flux:table.cell>
                        <flux:avatar circle name="Davin Alifianda" color="auto" />
                    </flux:table.cell>
                    <flux:table.cell>
                        <flux:heading>User profile</flux:heading>
                        <flux:text>This information will be displayed publicly.</flux:text>
                    </flux:table.cell>
                    <flux:table.cell align="end">
                        <flux:badge color="green" size="sm" variant="pill">Online</flux:badge>
                    </flux:table.cell>
                </flux:table.row>
                
                <flux:table.row>
                    <flux:table.cell>
                        <flux:avatar circle name="Haydar Aydin" color="auto" />
                    </flux:table.cell>
                    <flux:table.cell>
                        <flux:heading>User profile</flux:heading>
                        <flux:text>This information will be displayed publicly.</flux:text>
                    </flux:table.cell>
                    <flux:table.cell align="end">
                        <flux:badge color="yellow" size="sm" variant="pill">Delivery</flux:badge>
                    </flux:table.cell>
                </flux:table.row>

                <flux:table.row>
                    <flux:table.cell>
                        <flux:avatar circle name="Khilda" color="auto" />
                    </flux:table.cell>
                    <flux:table.cell>
                        <flux:heading>User profile</flux:heading>
                        <flux:text>This information will be displayed publicly.</flux:text>
                    </flux:table.cell>
                    <flux:table.cell align="end">
                        <flux:badge color="red" size="sm" variant="pill">Offline</flux:badge>
                    </flux:table.cell>
                </flux:table.row>
            </flux:table.rows>
        </flux:table>
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
        setTimeout(() => {
            if (window.themeObserver) {
                window.themeObserver.disconnect();
            }

            if (window.radialChart) {
                window.radialChart.destroy();
            }

            const getTheme = () => document.documentElement.classList.contains('dark') ? 'dark' : 'light';

            const getLabelColors = () => {
                return document.documentElement.classList.contains('dark')
                    ? { valueColor: '#f9fafb' } 
                    : { valueColor: '#111827' };
            }

            const chartElNasabahAktif = document.querySelector("#chart-nasabah-aktif");
            if (chartElNasabahAktif) {
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
                window.radialChart = new ApexCharts(chartElNasabahAktif, radialOptions);
                window.radialChart.render();

                window.themeObserver = new MutationObserver((mutations) => {
                    mutations.forEach((mutation) => {
                        if (mutation.attributeName === 'class') {
                            const newTheme = getTheme();
                            const newLabelColors = getLabelColors();
                            window.radialChart.updateOptions({
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
            }
        }, 0);
    });

    window.addEventListener('livewire:navigating', () => {
        if (window.radialChart) {
            window.radialChart.destroy();
            window.radialChart = null;
        }
        if (window.themeObserver) {
            window.themeObserver.disconnect();
            window.themeObserver = null;
        }
    });
</script>
@endscript