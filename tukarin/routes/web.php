<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('login');
})->name('login');

Route::prefix('admin')->group(function () {
    Route::get('/', function () {
        return view('admin.dashboard');
    })->name('admin.dashboard');
    
    Route::get('/sampah-point', function () {
        return view('admin.sampah-point');
    })->name('admin.sampah-point');

    Route::get('/transaksi-langsung', function () {
        return view('admin.transaksi-langsung');
    })->name('admin.transaksi-langsung');

    Route::get('/transaksi-jemput', function () {
        return view('admin.transaksi-jemput');
    })->name('admin.transaksi-jemput');
});
