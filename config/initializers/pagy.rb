# Pagy Configuration
require 'pagy/extras/overflow'

Pagy::DEFAULT[:items] = 25
Pagy:: DEFAULT[:size] = [1,4,4,1]
Pagy::DEFAULT[:overflow] = :last_page