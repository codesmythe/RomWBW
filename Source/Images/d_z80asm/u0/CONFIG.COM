� 15��f:e �  !CO  �"e >M2g \ �2h � <(M�2| \ � � >͞*� 2�R 8!� "!�"ͅ0�� � �2| \ � ͙\ � ���f���f�Use Legitimate Z80ASM file name$Not Z80ASM Release 1.32$ � ���� -�^���������0\ � � 1V{��6]�� � *Adz����J	n	�	�	�	�	
�Use TAB as separator between Symbols in .SYM$Page Width$Page Length$SPECIAL OPTIONS$List more than 4 bytes of object code$List lines encountered during a false conditional$Form Feed at start of listing$Macro Listing Option - 1=.LALL, 2=.XALL, 4=.SALL$Suppress Source lines containing PAGE, TITLE, etc.$Disable Interrupts$Force Form Feed before Summary$Form Feed at End of Listing$Time & Date in Listing$This item is significant only if T&D is selected, and
  you are supplying your own TIME and DATE values

What are you supplying, (N = address of values, Y= address of routine$Enter HEX address of time value/routine$Time & Date in ASCII$Take advantage of multi-sector I/O$Print 16-bit values in logical direction$Use Statement #'s instead of Line # in file$Print Line/Stmt # first on listing line$Generate 6 Significant in M-Rel instead of 7$Number of errors on which to abort$Number of lines per console page (0=no paging)$Number of bytes (1-60) per line of HEX output$Close and ReOpen File in 2-pass mode$Require : if label not in column one$Conditionals test only bit 0 (DRI Compatibility)$Suppress IF parameter errors in 1-pass mode$Ignore leading Space & Tab chars in IF <> types$Fill unused space with 0 (N) or FF (Y) in COM$Generate Empty External Chains (M-REL)$ASEG Default to 0H instead of 100H$ORG <ABSOLUTE> Yields Offset in Current Space$COMMON always back to relative address 0$Drive for temporary files (0=Default, 1=A, etc.)$Alternate User # to Search (0-31)$Erase ���.SUB on Error$Running under MSDOS-based Emulator$Allow Tabs in Strings$Print Nesting level in listing$Mask Off High Bit (bit 7)$Extension for source file$Extension for relocatable file$Extension for absolute binary file$Extension for non-standard (non-100H) absolute binary file$Extension for Intel-Hex format file$Extension for listing file$Extension for temporary file$Extension for /I file$Default Ext for MACLIB file$Leader String to send to printer (up to 8 HEX bytes, FF terminated)
$Trailer string to printer (up to 8 HEX bytes, FF terminated)
$ ($) - $There is a byte which defines several options.
Bit 0 selects the second-pass listing
Bit 1 selects the first-pass listing
Bit 2 selects the symbol table output
Bit 3 selects cross-reference generation
Bit 4 selects automatic external declaration
Bit 5 selects Upper/Lower case distinction
Bit 6 & 7 define binary output type
Bit 7=0 6=0 selects .COM type
Bit 7=0 6=1 selects .HEX type
Bit 7=1 6=0 selects .REL SLR format
Bit 7=1 6=1 selects .REL MSFT format

The current settings are:
76543210
$
Bit # to be flipped :$*###"�*~�#^#V#"�(���f]
�f��k=ʰ=�=�3=(M*~��(�#��f�*"`
�f�:(ڞ*w#"�� ��f�* "�*^#~�{�`
�f�W(ڞ�*s#r#"�*##"�*T]###~6����`
�f��w��(#�[�������S�*###"�*n& !�p>$!�f`
�f��(#ͼ8}*w*#"�� *+++"��e
�f*�00�� ��c�f�M� 8�0�8H�f�G�>(�*�w�*#"��f��*~Y� N� `
�f�M� 8�Y�(�N *q��f*#"��H�f� $���� ����a8�{0� �����	� ��� 0���ͮ(���ͮ(����ͮ(����ͮ(��}�0�ɯ<8��R=��0�����!  x)DM))	G�0�
0�o8����$�7���!  ".!-�M�(w#�>����f�!,w�����_� ����#���0�:8����_� �����}���O�}8�(
�����O��y��!  �}(�}8())))�o�������f����M���0��
8����8��7�?�>2�5!� ��� \ � ����ɺ��	�!� CP/M Emulator Required$
$,$Z80ASM Configuration Utility (c) 1983-86 SLR Systems
$                                                                                                     