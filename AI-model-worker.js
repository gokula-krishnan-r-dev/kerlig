/**
 * Enhanced Cloudflare Worker for AI Gateway with In-Memory Caching
 * - Uses request body for cache key generation
 * - No dependencies on KV or Cache services
 * - Implements efficient memory-based LRU cache
 */

// CORS configuration with security best practices
const CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Api-Key',
    'Content-Type': 'application/json',
  };
  
  // Default configuration
  const CONFIG = {
    defaultModel: '@cf/meta/llama-3.3-70b-instruct-fp8-fast',
    defaultTemperature: 0.7,
    defaultMaxTokens: 1024,
    logLevel: 'info', // 'debug', 'info', 'warn', 'error'
    cache: {
      enabled: true,
      maxItems: 100, // Maximum number of items to keep in cache
      ttl: 3600, // TTL in seconds (1 hour)
    }
  };
  
  /**
   * Simple LRU Cache implementation
   * - Uses global scope for persistence between requests
   * - Implements time-based expiration
   * - Limits maximum items stored
   */
  class MemoryCache {
    constructor() {
      // Use global cache object if it exists, otherwise create a new one
      if (!globalThis._memCache) {
        globalThis._memCache = {
          items: new Map(),
          created: Date.now()
        };
      }
      this.cache = globalThis._memCache;
    }
  
    /**
     * Generate a cache key from input data
     * @param {Object} data - Input data to hash
     * @returns {string} - A hash string to use as cache key
     */
    generateKey(data) {
      // If explicit cache key is provided, use it
      if (data.cacheKey) {
        return `custom:${data.cacheKey}`;
      }
      
      // Use only the essential properties for key generation
      const keyData = {
        model: data.model,
        instruction: data.instruction,
        text: data.text,
        temperature: data.temperature,
        max_tokens: data.max_tokens
      };
      
      // Create simple hash from the content (good enough for basic caching)
      // Using base64 encoding of JSON string as key
      return 'req:' + btoa(JSON.stringify(keyData));
    }
  
    /**
     * Get an item from cache
     * @param {string} key - Cache key
     * @returns {Object|null} - Cached value or null if not found/expired
     */
    get(key) {
      const item = this.cache.items.get(key);
      
      // Return null if item not found
      if (!item) return null;
      
      // Check if item has expired
      if (Date.now() > item.expiry) {
        this.cache.items.delete(key);
        return null;
      }
      
      // Update access time (for LRU behavior)
      item.lastAccessed = Date.now();
      return item.value;
    }
  
    /**
     * Store an item in cache
     * @param {string} key - Cache key
     * @param {*} value - Value to store
     * @param {number} ttl - Time to live in seconds
     */
    set(key, value, ttl = CONFIG.cache.ttl) {
      // Enforce cache size limits
      if (this.cache.items.size >= CONFIG.cache.maxItems) {
        // Find and remove least recently used item
        let oldestKey = null;
        let oldestTime = Date.now();
        
        for (const [k, item] of this.cache.items.entries()) {
          if (item.lastAccessed < oldestTime) {
            oldestTime = item.lastAccessed;
            oldestKey = k;
          }
        }
        
        if (oldestKey) {
          this.cache.items.delete(oldestKey);
        }
      }
      
      // Calculate expiry time
      const expiry = Date.now() + (ttl * 1000);
      
      // Store the item with metadata
      this.cache.items.set(key, {
        value,
        expiry,
        lastAccessed: Date.now()
      });
      
      return true;
    }
  
    /**
     * Get cache stats for monitoring
     * @returns {Object} - Cache statistics
     */
    getStats() {
      let validItems = 0;
      let expiredItems = 0;
      const now = Date.now();
      
      for (const item of this.cache.items.values()) {
        if (now <= item.expiry) {
          validItems++;
        } else {
          expiredItems++;
        }
      }
      
      return {
        totalItems: this.cache.items.size,
        validItems,
        expiredItems,
        cacheAge: Math.round((now - this.cache.created) / 1000) // in seconds
      };
    }
  
    /**
     * Purge expired items from cache
     * @returns {number} - Number of items purged
     */
    purgeExpired() {
      let purged = 0;
      const now = Date.now();
      
      for (const [key, item] of this.cache.items.entries()) {
        if (now > item.expiry) {
          this.cache.items.delete(key);
          purged++;
        }
      }
      
      return purged;
    }
  }
  
  // Create cache instance
  const memCache = new MemoryCache();
  
  // Logger utility
  const logger = {
    debug: (...args) => CONFIG.logLevel === 'debug' && console.debug(...args),
    info: (...args) => ['debug', 'info'].includes(CONFIG.logLevel) && console.info(...args),
    warn: (...args) => ['debug', 'info', 'warn'].includes(CONFIG.logLevel) && console.warn(...args),
    error: (...args) => console.error(...args),
  };
  
  /**
   * Handles the response including error formatting
   * @param {Object} data - The data to return
   * @param {number} status - HTTP status code
   * @returns {Response} - Formatted Response object
   */
  function createResponse(data, status = 200) {
    return new Response(JSON.stringify(data), {
      status,
      headers: CORS_HEADERS,
    });
  }
  
  /**
   * Error response handler
   * @param {string} message - Error message
   * @param {number} status - HTTP status code
   * @param {Error} [error] - Original error object
   * @returns {Response} - Formatted error Response
   */
  function errorResponse(message, status = 500, error = null) {
    logger.error(`Error (${status}): ${message}`, error);
    
    const payload = { 
      error: message,
      status,
      timestamp: new Date().toISOString()
    };
    
    
    
    return createResponse(payload, status);
  }
  
  /**
   * Validate input parameters and apply defaults
   * @param {Object} requestData - The request data
   * @returns {Object} - Validated request data with defaults applied
   */
  function validateAndNormalizeInput(requestData) {
    // Validate instruction and text
    if (!requestData.instruction || typeof requestData.instruction !== 'string') {
      throw new Error('Missing or invalid instruction parameter');
    }
    
    if (!requestData.text || typeof requestData.text !== 'string') {
      throw new Error('Missing or invalid text parameter');
    }
    
    // Apply defaults and normalize
    return {
      model: requestData.model || CONFIG.defaultModel,
      temperature: parseFloat(requestData.temperature || CONFIG.defaultTemperature),
      max_tokens: parseInt(requestData.max_tokens || CONFIG.defaultMaxTokens, 10),
      instruction: requestData.instruction.trim(),
      text: requestData.text.trim(),
      stream: Boolean(requestData.stream || false),
      cacheKey: requestData.cacheKey || null,
      skipCache: Boolean(requestData.skipCache || false)
    };
  }
  
  /**
   * Main handler for the Cloudflare Worker
   */
  export default {
    async fetch(request, env, ctx) {
      // Occasionally purge expired cache items (1% chance per request)
      if (Math.random() < 0.01) {
        const purged = memCache.purgeExpired();
        if (purged > 0) {
          logger.info(`Cache maintenance: purged ${purged} expired items`);
        }
      }
      
      // Handle CORS preflight requests
      if (request.method === "OPTIONS") {
        return new Response(null, {
          status: 204,
          headers: CORS_HEADERS
        });
      }
      
      // Handle cache stats request - useful for monitoring
      if (request.url.endsWith('/cache-stats') && request.method === "GET") {
        if (CONFIG.cache.enabled) {
          return createResponse({
            cacheEnabled: true,
            stats: memCache.getStats(),
            config: {
              maxItems: CONFIG.cache.maxItems,
              ttl: CONFIG.cache.ttl
            }
          });
        } else {
          return createResponse({ cacheEnabled: false });
        }
      }
      
      // Validate request method
      if (request.method !== "POST") {
        return errorResponse("Only POST requests are allowed", 405);
      }
      
      try {
        // Clone the request for potential reuse
        const requestClone = request.clone();
        
        // Parse request body
        let requestData;
        try {
          requestData = await request.json();
        } catch (jsonError) {
          return errorResponse("Invalid JSON in request body", 400, jsonError);
        }
  
        console.log(requestData , "requestdata")
        
        // Validate and normalize input parameters
        let normalizedParams;
        try {
          normalizedParams = validateAndNormalizeInput(requestData);
          logger.debug('Normalized parameters:', normalizedParams);
        } catch (validationError) {
          return errorResponse(validationError.message, 400, validationError);
        }
        
        // Check cache for matching request
        if (CONFIG.cache.enabled && !normalizedParams.stream && !normalizedParams.skipCache) {
          const cacheKey = memCache.generateKey(normalizedParams);
          const cachedResponse = memCache.get(cacheKey);
          
          if (cachedResponse) {
            logger.info('Cache hit:', cacheKey);
            
            // Add cache metadata
            cachedResponse.metadata = {
              ...cachedResponse.metadata,
              cached: true,
              cacheKey
            };
            
            return createResponse(cachedResponse);
          }
          logger.debug('Cache miss:', cacheKey);
        }
        
        // Create LLM request payload
        const llmPayload = {
          messages: [
            {
              role: "system",
              content: normalizedParams.instruction
            },
            {
              role: "user",
              content: normalizedParams.text
            }
          ],
          temperature: normalizedParams.temperature,
          max_tokens: normalizedParams.max_tokens,
          stream: normalizedParams.stream
        };
        
        logger.info(`Sending request to model: ${normalizedParams.model}`);
        
        // Handle streaming responses if requested
        if (normalizedParams.stream) {
          const aiStream = await env.AI.run(normalizedParams.model, llmPayload);
          return new Response(aiStream, { headers: CORS_HEADERS });
        }
        
        // Make regular request to Cloudflare AI
        const startTime = performance.now();
        const aiResponse = await env.AI.run(normalizedParams.model, llmPayload);
        const endTime = performance.now();
        
        const processingTime = Math.round(endTime - startTime);
        logger.info(`AI request completed in ${processingTime}ms`);
        
        // Process and format the response
        const responsePayload = typeof aiResponse === "string"
          ? { response: aiResponse }
          : aiResponse;
        
        // Add metadata to response
        const finalResponse = {
          ...responsePayload,
          metadata: {
            model: normalizedParams.model,
            processing_time_ms: processingTime,
            timestamp: new Date().toISOString(),
            cached: false
          }
        };
        
        // Store in cache if appropriate
        if (CONFIG.cache.enabled && !normalizedParams.stream && !normalizedParams.skipCache) {
          const cacheKey = memCache.generateKey(normalizedParams);
          memCache.set(cacheKey, finalResponse);
          logger.debug('Response cached with key:', cacheKey);
          
          // Add cache key to metadata
          finalResponse.metadata.cacheKey = cacheKey;
        }
        
        return createResponse(finalResponse);
        
      } catch (error) {
        // Handle different types of errors appropriately
        if (error.name === "TypeError" && error.message.includes("env.AI")) {
          return errorResponse("AI service not available. Make sure Cloudflare AI is enabled for your Worker.", 500, error);
        } else {
          return errorResponse("Internal server error. Please try again later.", 500, error);
        }
      }
    },
  };