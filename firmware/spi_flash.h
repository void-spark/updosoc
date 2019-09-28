#ifndef SPI_FLASH_H
#define SPI_FLASH_H

#include <stdint.h>

void flashio(uint8_t *data, int len, uint8_t wrencmd);

void set_flash_qspi_flag();

void set_flash_mode_spi();

void set_flash_mode_dual();

void set_flash_mode_quad();

void set_flash_mode_qddr();

void enable_flash_crm();

#endif