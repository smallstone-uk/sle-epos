<?php

require __DIR__.'/../vendor/autoload.php';

$payment = new ePayments\Payment;

echo '<pre>';
print_r($payment->client());
echo '</pre>';
