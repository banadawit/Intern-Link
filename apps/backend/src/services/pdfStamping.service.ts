import { PDFDocument, rgb } from 'pdf-lib';
import { CloudinaryService } from './cloudinary.service';

export interface StampOptions {
  stampImageUrl: string;
  position?: {
    x: number;
    y: number;
  };
  size?: {
    width: number;
    height: number;
  };
}

export class PDFStampingService {
  /**
   * Add stamp to PDF
   */
  static async stampPDF(
    pdfBuffer: Buffer,
    options: StampOptions
  ): Promise<Buffer> {
    try {
      // Load the PDF
      const pdfDoc = await PDFDocument.load(pdfBuffer);

      // Download stamp image
      const stampImageBuffer = await CloudinaryService.downloadFile(
        options.stampImageUrl
      );

      // Embed the stamp image
      let stampImage;
      const imageType = options.stampImageUrl.toLowerCase();
      if (imageType.includes('.png')) {
        stampImage = await pdfDoc.embedPng(stampImageBuffer);
      } else if (imageType.includes('.jpg') || imageType.includes('.jpeg')) {
        stampImage = await pdfDoc.embedJpg(stampImageBuffer);
      } else {
        throw new Error('Unsupported stamp image format. Use PNG or JPG.');
      }

      // Get the last page (where stamp typically goes)
      const pages = pdfDoc.getPages();
      const lastPage = pages[pages.length - 1];
      const { width: pageWidth, height: pageHeight } = lastPage.getSize();

      // Default position: bottom-right corner
      const stampWidth = options.size?.width || 150;
      const stampHeight = options.size?.height || 100;
      const x = options.position?.x || pageWidth - stampWidth - 50;
      const y = options.position?.y || 50;

      // Draw the stamp
      lastPage.drawImage(stampImage, {
        x,
        y,
        width: stampWidth,
        height: stampHeight,
      });

      // Add "Verified" text above stamp
      lastPage.drawText('Company Verified', {
        x: x + 10,
        y: y + stampHeight + 10,
        size: 10,
        color: rgb(0, 0, 0),
      });

      // Serialize the PDF
      const stampedPdfBytes = await pdfDoc.save();
      return Buffer.from(stampedPdfBytes);
    } catch (error: any) {
      console.error('PDF stamping error:', error);
      throw new Error(`Failed to stamp PDF: ${error.message}`);
    }
  }

  /**
   * Stamp PDF from URL and upload result
   */
  static async stampAndUploadPDF(
    pdfUrl: string,
    stampImageUrl: string,
    uploadOptions: {
      userId: number;
      organizationId: number;
      folder: string;
    }
  ): Promise<{ success: boolean; url?: string; error?: string }> {
    try {
      // Download original PDF
      const pdfBuffer = await CloudinaryService.downloadFile(pdfUrl);

      // Stamp the PDF
      const stampedPdfBuffer = await this.stampPDF(pdfBuffer, {
        stampImageUrl,
      });

      // Create a file object for upload
      const stampedFile = {
        buffer: stampedPdfBuffer,
        originalname: 'stamped-report.pdf',
        mimetype: 'application/pdf',
        size: stampedPdfBuffer.length,
      } as Express.Multer.File;

      // Upload stamped PDF
      const uploadResult = await CloudinaryService.uploadDocument(stampedFile, {
        userId: uploadOptions.userId,
        organizationId: uploadOptions.organizationId,
        fileType: 'FINAL_REPORT',
        folder: uploadOptions.folder,
        resourceType: 'raw',
      });

      return uploadResult;
    } catch (error: any) {
      console.error('Stamp and upload error:', error);
      return { success: false, error: error.message };
    }
  }
}
