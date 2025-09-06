<?php

use function Livewire\Volt\{state};

//

?>

<div>
    <flux:dropdown>
        <flux:button icon="cloud-download" size="sm">Export</flux:button>

        <flux:menu>
            <flux:menu.item icon="file-text">PDF</flux:menu.item>
            <flux:menu.item icon="file-spreadsheet">Excel</flux:menu.item>
        </flux:menu>
    </flux:dropdown>
</div>