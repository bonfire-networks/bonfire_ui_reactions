import 'emoji-picker-element';
// Fix: Import Database as default export, not named export
import Database from 'emoji-picker-element/database';

const ReactionPicker = {
  // Store the handler function to remove it later
  emojiClickHandler: null,
  skinToneChangeHandler: null,
  database: null,
  
  // Add a method to get database only when needed
  async getDatabase() {
    if (!this.database) {
      try {
        // Only create the database when needed
        this.database = new Database();
        await this.database.ready(); // Ensure database is ready
      } catch (err) {
        console.warn("Could not initialize emoji database:", err);
      }
    }
    return this.database;
  },
  
  // Add a method to safely close database
  closeDatabase() {
    if (this.database) {
      try {
        this.database.close();
      } catch (err) {
        console.warn('Error closing emoji database:', err);
      }
      this.database = null;
    }
  },

  mounted() {
    const picker = this.el.querySelector('emoji-picker');
    if (!picker) {
      console.error("Emoji picker element not found within hook's element:", this.el);
      return;
    }
    const objectId = this.el.dataset.objectId;

    // Database is no longer initialized here - it will be initialized on demand

    // Try to get custom emojis from data attribute first
    try {
      const emojisData = picker.getAttribute('data-emojis');
      if (emojisData) {
        picker.customEmoji = JSON.parse(emojisData);
      }
    } catch (e) {
      console.error('Failed to parse custom emojis from data-emojis attribute:', e);
    }

    // Fallback to picker container if needed
    const pickerContainer = document.querySelector('#emoji-picker-in-composer');
    if (pickerContainer && (!picker.customEmoji || picker.customEmoji.length === 0)) {
      try {
        const emojisData = pickerContainer.getAttribute('data-emojis');
        if (emojisData) {
          picker.customEmoji = JSON.parse(emojisData);
        }
      } catch (e) {
        console.error('Failed to parse custom emojis from container:', e);
      }
    }

    // If we still don't have custom emoji, try to get them from the server
    // if (!picker.customEmoji || picker.customEmoji.length === 0) {
    //   this.pushEvent("get_custom_emojis", {}, (response) => {
    //     if (response && response.custom_emoji) {
    //       picker.customEmoji = response.custom_emoji;
    //     }
    //   });
    // }

    // Make picker visible when tooltip is opened
    const tooltipButton = this.el.querySelector('.tooltip-button');
    if (tooltipButton) {
      tooltipButton.addEventListener('click', () => {
        // Ensure picker is visible
        picker.classList.remove('hidden');
        
        // Initialize database when picker is opened
        this.getDatabase().catch(err => {
          console.warn('Failed to initialize database on picker open:', err);
        });
      });
    }

    // Define the emoji click handler
    this.emojiClickHandler = async (event) => {
      // Update favorite emoji in database if available - now using the getDatabase method
      try {
        const database = await this.getDatabase();
        if (database) {
          const unicodeOrName = event.detail.unicode || 
            (event.detail.emoji && (event.detail.emoji.annotation || event.detail.emoji.name || event.detail.emoji.shortcodes && event.detail.emoji.shortcodes[0]));
          
          if (unicodeOrName) {
            database.incrementFavoriteEmojiCount(unicodeOrName).catch(err => {
              console.warn('Failed to increment emoji favorite count:', err);
            });
          }
        }
      } catch (err) {
        console.warn('Error tracking favorite emoji:', err);
      }

      // Send the reaction to the server with proper fallbacks for missing data
      this.pushEventTo(this.el, "Bonfire.Social.Likes:add_reaction", {
        emoji: event.detail.unicode || 
          (event.detail.emoji && event.detail.emoji.shortcodes && event.detail.emoji.shortcodes[0]),
        emoji_id: event.detail.emoji && event.detail.emoji.id,
        id: objectId,
        label: event.detail.emoji && (event.detail.emoji.annotation || event.detail.emoji.name)
      });

      // Close tooltip after selection
      if (tooltipButton) {
        tooltipButton.click();
        
        // Close database after emoji selection
        // Wait a bit to ensure any pending operations complete
        setTimeout(() => this.closeDatabase(), 500);
      }
    };

    // Add skin tone change handler
    this.skinToneChangeHandler = async (event) => {
      // The emoji-picker-element library handles skin tone persistence automatically
      console.debug('Skin tone changed:', event.detail.skinTone);
      
      // We need database access here to save the setting
      try {
        const database = await this.getDatabase();
        if (database) {
          await database.setPreferredSkinTone(event.detail.skinTone);
        }
      } catch (err) {
        console.warn('Error saving skin tone preference:', err);
      }
    };

    // Add event listeners
    picker.addEventListener('emoji-click', this.emojiClickHandler);
    picker.addEventListener('skin-tone-change', this.skinToneChangeHandler);
  },

  destroyed() {
    const picker = this.el.querySelector('emoji-picker');
    
    // Remove event listeners if they were added
    if (picker) {
      if (this.emojiClickHandler) {
        picker.removeEventListener('emoji-click', this.emojiClickHandler);
        this.emojiClickHandler = null;
      }
      
      if (this.skinToneChangeHandler) {
        picker.removeEventListener('skin-tone-change', this.skinToneChangeHandler);
        this.skinToneChangeHandler = null;
      }
    }
    
    // Close database connection to clean up resources
    this.closeDatabase();
  }
};

export default ReactionPicker;
