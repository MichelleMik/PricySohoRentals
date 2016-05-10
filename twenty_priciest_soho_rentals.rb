require 'HTTParty'
require 'Nokogiri'
require 'pry'




class Rental
attr_accessor :rentals_array
  def initialize
    @rentals_array = []
  end


  def get_page(page_num)
    link = 'http://streeteasy.com/for-rent/soho?page=' + page_num +'&sort_by=price_desc'
    page = HTTParty.get(link)
  end

  def parse_page(page)
    parse_page = Nokogiri::HTML(page)
  end

  def setup_rental_hash
    h = {}    
    ary = [:listing_class, :address, :unit, :url, :price]
    ary.each{|a| h[a] = ""}
    h
  end

  def parse_address(hash, address)
    if address.include?('#')
      street_address = address.split("#")[0]
      unit = '#' + address.split("#")[1]
    else
      street_address = address
      unit = "N/A"
    end
    set_unit(hash,unit)
    set_address(hash,street_address)
  end

  def set_unit(hash, unit)
    hash[:unit] = unit
  end

  def set_address(hash, address)
    hash[:address] = address
  end

  def set_url(hash,url)
    hash[:url] = url
  end

  def set_price(hash,rental)
    hash[:price] = rental.css(".price-info").css('.price').text.gsub(/\D/,'').to_i
  end

  def set_listing_class(hash)
    hash[:listing_class] = self.class.to_s.downcase
  end



  def create_hash_to_be_jsonified(page_name)
    rentals = []
    page_name.css('.items').css('.item').css('.details').each do |item|
      rental_hash = setup_rental_hash
      link = item.css('.details-title').css('a')
      url = "http://streeteasy.com#{link[0]["href"]}"
      rental_address = link.text[/(.*)\s/,1]
      set_listing_class(rental_hash)
      parse_address(rental_hash,rental_address)
      set_url(rental_hash, url)
      set_price(rental_hash, item)
      @rentals_array.push(rental_hash)
    end
    
  end

  def sort_by_price
     @rentals_array = @rentals_array.sort{|x,y|y[:price] <=> x[:price]}
  end

  def twenty_priciest
    @rentals_array = @rentals_array.slice!(0,20)
  end

  def runner
    page_one = get_page("1")
    parsed_page_one = parse_page(page_one)
    create_hash_to_be_jsonified(parsed_page_one)
    page_two = get_page("2")
    parsed_page_two = parse_page(page_two)
    create_hash_to_be_jsonified(parsed_page_two)
    sort_by_price
    twenty_priciest
    write_to_file(@rentals_array)
    puts JSON.pretty_generate(@rentals_array)
    puts @rentals_array.size
  end

  def write_to_file(arr)
    File.open("priciest_twenty_soho_rentals.json","w") do |f|
      f.write(JSON.pretty_generate(arr))
    end
  end

end

@rental = Rental.new
@rental.runner










 
