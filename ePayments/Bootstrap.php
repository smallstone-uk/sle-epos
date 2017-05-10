<?php

namespace ePayments;

use Ingenico\Connect\Sdk\Client;
use Ingenico\Connect\Sdk\Communicator;
use Ingenico\Connect\Sdk\CommunicatorConfiguration;
use Ingenico\Connect\Sdk\DefaultConnection;

class Bootstrap
{
    protected $client;
    protected $communicator;

    /**
     * Constructor method.
     *
     * @return any
     */
    public function __construct()
    {
        // Load environment config
        $dotenv = new \Dotenv\Dotenv(__DIR__);
        $dotenv->load();

        // Setup the SDK
        $this->setupSdk();
    }

    /**
     * Sets up the SDK.
     *
     * @return any
     */
    public function setupSdk()
    {
        $communicatorConfiguration = new CommunicatorConfiguration(
            getenv('EPAY_APIKEYID'),
            getenv('EPAY_APISECRET'),
            getenv('EPAY_BASEURI'),
            getenv('EPAY_INTEGRATOR')
        );

        $connection = new DefaultConnection();
        $this->communicator = new Communicator($connection, $communicatorConfiguration);
        $this->client = new Client($this->communicator);

        return $this;
    }
}
